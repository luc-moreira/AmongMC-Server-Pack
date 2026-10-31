# How to Translate

This guide explains how to add a new language to the project.

## 1. Read `translate.sk`

Before creating a translation, **read `translate.sk` first** to understand how the translation system works and how translation IDs are organized.

This will help you understand the expected format and how the translated strings are used throughout the project.

## 2. Create the language file

Create a new `.sk` file using the language code as its name.

For example, for French:

```text
fr.sk
```

Add the translations using the same format used by the other language files.

Then, **register the new language in `translate.sk`** so the game knows that it is available.

## 3. Run `checkmissing.py`

Run:

```text
checkmissing.py
```

When prompted for the language, enter the language code you just created.

For example:

```text
fr
```

The script will check which translations are missing compared to the reference languages (`en` and `ptbr`).

You will also be asked:

```text
Do you want to include comments with reference translations? (y/n):
```

It is recommended to answer **`y`** when translating a new language. This adds a reference translation above each missing entry, making it easier to understand the context of the string.

The script will generate a file such as:

```text
missing_translations_fr.txt
```

## 4. Translate the missing entries

Open the generated `.txt` file and translate all the entries that were generated.

For example:

```skript
# [en] You have been assigned a new task.
registerTranslation("fr", "task.newTask", "")
```

becomes:

```skript
# [en] You have been assigned a new task.
registerTranslation("fr", "task.newTask", "Une nouvelle tâche vous a été attribuée.")
```

Make sure to preserve the translation ID and only modify the text inside the final quotes.

The reference comments are only there to help you understand the original text. They do not need to be translated or copied into the language file.

## 5. Run `updatetranslations.py`

After translating all the entries, run:

```text
updatetranslations.py
```

The script will open a file selection window.

Select the `missing_translations_<language>.txt` file you just completed.

For example:

```text
missing_translations_fr.txt
```

The script will then ask for confirmation:

```text
This will append all the modified translations to the game. Proceed? (y/N):
```

Enter:

```text
y
```

The script will automatically insert the translated entries into the correct positions in the language file.

## 6. Done

The new language should now be complete and registered in the translation system.

In short:

1. Read `translate.sk`.
2. Create your language file, e.g. `fr.sk`.
3. Register the language in `translate.sk`.
4. Run `checkmissing.py`.
5. Enter your language code.
6. Optionally enable reference comments.
7. Translate all entries in the generated `.txt` file.
8. Run `updatetranslations.py`.
9. Select the generated `.txt` file.
10. Confirm with `y`.
