import re
from pathlib import Path

folder = Path(__file__).parent

# Todos os .sk, exceto translate.sk
files = [
    file for file in folder.glob("*.sk")
    if file.name.lower() != "translate.sk"
]

# Inputs
select = input(
    "Type the language to check (e.g., en, ptbr) or press enter to check all: "
).strip().lower()

comment = input(
    "Do you want to include comments with reference translations? (Y/n): "
).strip().lower() != "n"

# ID -> {idioma: tradução}
translations = {}

# Arquivo -> conjunto de IDs
ids_by_file = {}

# IDs que existem em en ou ptbr
reference_ids = set()

pattern = re.compile(
    r'registerTranslation\(\s*"[^"]+"\s*,\s*"([^"]+)"\s*,\s*"([^"]*)"'
)

# Lê todos os arquivos
for file in files:
    language = file.stem
    content = file.read_text(encoding="utf-8")

    ids = set()

    for translation_id, translation_text in pattern.findall(content):
        ids.add(translation_id)

        if translation_id not in translations:
            translations[translation_id] = {}

        translations[translation_id][language] = translation_text

        # Somente en e ptbr definem quais IDs deveriam existir
        if language in ("en", "ptbr"):
            reference_ids.add(translation_id)

    ids_by_file[file.name] = ids


def get_reference_translation(translation_id, current_language):
    """
    Procura uma tradução de referência.

    Ordem:
    1. en
    2. ptbr

    O próprio idioma nunca é usado como referência.
    """

    available = translations.get(translation_id, {})

    if current_language != "en" and "en" in available:
        return "en", available["en"]

    if current_language != "ptbr" and "ptbr" in available:
        return "ptbr", available["ptbr"]

    return None, None


# Gera o resultado
output = []

# Define quais arquivos serão verificados
if select:
    selected_files = [
        file for file in files
        if file.stem.lower() == select
    ]

    if not selected_files:
        output.append(f"WARNING: Language '{select}' was not found.")
else:
    selected_files = sorted(
        files,
        key=lambda f: f.name.lower()
    )


for file in selected_files:
    language = file.stem
    ids = ids_by_file[file.name]

    # IDs que deveriam existir, mas estão faltando
    missing = sorted(reference_ids - ids)

    # IDs que existem no idioma, mas não existem em en ou ptbr
    unknown = sorted(ids - reference_ids)

    output.append(f"===== {file.name} =====")

    # Avisos sobre IDs desconhecidos
    if unknown:
        output.append(
            "WARNING: The following IDs exist in this language "
            "but do not exist in en or ptbr:"
        )

        for translation_id in unknown:
            output.append(
                f'    {translation_id}'
            )

        output.append("")

    # Traduções faltantes
    if not missing:
        output.append("No missing translations found.")
    else:
        for translation_id in missing:

            if comment:
                reference_language, reference_text = get_reference_translation(
                    translation_id,
                    language
                )

                if reference_language is not None:
                    output.append(
                        f'\n# [{reference_language}] {reference_text}'
                    )

            output.append(
                f'    registerTranslation("{language}", "{translation_id}", "")'
            )

    output.append("")


# Salva o resultado
if select:
    output_file = folder / f"missing_translations_{select}.txt"
else:
    output_file = folder / "missing_translations.txt"

output_file.write_text(
    "\n".join(output),
    encoding="utf-8"
)

print(f"Files Checked: {len(selected_files)}")
print(f"Reference IDs (en + ptbr): {len(reference_ids)}")
print(f"Result saved to: {output_file}")