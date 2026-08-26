import re
import tkinter as tk
from tkinter import filedialog, messagebox
from pathlib import Path


folder = Path(__file__).parent

root = tk.Tk()
root.withdraw()

selected_file = filedialog.askopenfilename(
    title="Select missing translations file",
    initialdir=folder,
    filetypes=[
        ("Text files", "*.txt"),
        ("All files", "*.*")
    ]
)

if not selected_file:
    print("No file selected.")
    exit()


print(f"Selected file: {selected_file}")

confirmation = input(
    "This will append all the modified translations to the game. "
    "Proceed? (y/N): "
).strip().lower()

if confirmation != "y":
    print("Operation cancelled.")
    exit()


section_pattern = re.compile(
    r'^===== (.+?) =====$',
    re.MULTILINE
)

translation_pattern = re.compile(
    r'registerTranslation\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]*)"\s*\)'
)

selected_path = Path(selected_file)
content = selected_path.read_text(encoding="utf-8")

sections = list(section_pattern.finditer(content))

translations_to_add = {}


for i, section in enumerate(sections):

    filename = section.group(1).strip()

    start = section.end()

    if i + 1 < len(sections):
        end = sections[i + 1].start()
    else:
        end = len(content)

    section_content = content[start:end]

    language = Path(filename).stem

    entries = []

    for match in translation_pattern.finditer(section_content):

        entry_language = match.group(1)
        translation_id = match.group(2)
        translation_text = match.group(3)

        if not translation_text:
            continue

        if entry_language != language:
            continue

        entries.append({
            "id": translation_id,
            "text": translation_text
        })

    if entries:
        translations_to_add[language] = entries


en_file = folder / "en.sk"
ptbr_file = folder / "ptbr.sk"

if not en_file.exists():
    print("WARNING: en.sk was not found.")

if not ptbr_file.exists():
    print("WARNING: ptbr.sk was not found.")


def read_translation_file(path):
    """
    Retorna:
        id -> posição ordinal da tradução
    """

    if not path.exists():
        return {}

    content = path.read_text(encoding="utf-8")

    result = {}

    matches = list(translation_pattern.finditer(content))

    for index, match in enumerate(matches):
        translation_id = match.group(2)

        if translation_id not in result:
            result[translation_id] = index

    return result


en_positions = read_translation_file(en_file)
ptbr_positions = read_translation_file(ptbr_file)


def get_reference_position(translation_id, language):
    """
    Retorna a posição ordinal do ID na linguagem de referência.

    Para en:
        usa ptbr

    Para ptbr:
        usa en

    Para outras:
        usa en primeiro e ptbr depois.
    """

    if language == "en":
        if translation_id in ptbr_positions:
            return ptbr_positions[translation_id]
        return None

    if language == "ptbr":
        if translation_id in en_positions:
            return en_positions[translation_id]
        return None

    if translation_id in en_positions:
        return en_positions[translation_id]

    if translation_id in ptbr_positions:
        return ptbr_positions[translation_id]

    return None


for language, entries in translations_to_add.items():

    target_file = folder / f"{language}.sk"

    if not target_file.exists():
        print(f"WARNING: {target_file.name} was not found.")
        continue

    target_content = target_file.read_text(encoding="utf-8")

    target_matches = list(
        translation_pattern.finditer(target_content)
    )

    existing_ids = {
        match.group(2)
        for match in target_matches
    }

    new_entries = []

    for entry in entries:

        translation_id = entry["id"]

        if translation_id in existing_ids:
            continue

        reference_position = get_reference_position(
            translation_id,
            language
        )

        if reference_position is None:
            print(
                f"WARNING: Could not find reference position for "
                f"{language}:{translation_id}"
            )
            continue

        new_entries.append({
            "id": translation_id,
            "text": entry["text"],
            "reference_position": reference_position
        })

    if not new_entries:
        print(f"{target_file.name}: Nothing to add.")
        continue

    insertions = []

    for entry in new_entries:

        reference_position = entry["reference_position"]

        insertion_position = None
        indentation = "    "

        for target_match in target_matches:

            target_id = target_match.group(2)

            target_reference_position = get_reference_position(
                target_id,
                language
            )

            if target_reference_position is None:
                continue

            if target_reference_position > reference_position:

                line_start = target_content.rfind(
                    "\n",
                    0,
                    target_match.start()
                ) + 1

                insertion_position = line_start

                line = target_content[
                    line_start:target_match.start()
                ]

                indentation = line

                break

        new_line = (
            f'{indentation}registerTranslation("{language}", '
            f'"{entry["id"]}", "{entry["text"]}")\n'
        )

        if insertion_position is None:

            insertion_position = len(target_content)

            if target_content and not target_content.endswith("\n"):
                new_line = "\n" + new_line

        insertions.append({
            "position": insertion_position,
            "text": new_line,
            "id": entry["id"]
        })


    insertions.sort(
        key=lambda x: x["position"],
        reverse=True
    )

    for insertion in insertions:

        position = insertion["position"]

        target_content = (
            target_content[:position]
            + insertion["text"]
            + target_content[position:]
        )

    target_file.write_text(
        target_content,
        encoding="utf-8"
    )

    print(
        f"{target_file.name}: "
        f"{len(insertions)} translation(s) added."
    )


print()
input("Done.")