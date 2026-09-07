import os
import re

# Dieser Regex ist dank re.DOTALL immun gegen jegliche Zeilenumbrüche und Leerzeichen
pattern = re.compile(
    r"Translator\.get\(\s*(['\"])(.*?)\1\s*,?\s*\)\s*!=\s*['\"]\2['\"]\s*\?\s*Translator\.get\(\s*['\"]\2['\"]\s*,?\s*\)\s*:\s*(['\"])(.*?)\3",
    re.DOTALL
)

def main():
    lib_dir = 'lib'
    total_replacements = 0
    
    # Gehe rekursiv durch alle Ordner im 'lib' Verzeichnis
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Führe die Ersetzung durch
                new_content, count = pattern.subn(r"Translator.get(\1\2\1, fallback: \3\4\3)", content)
                
                # Wenn etwas geändert wurde, speichere die Datei neu ab
                if count > 0:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"[{count} Treffer] refactored in -> {filepath}")
                    total_replacements += count
                    
    print(f"\nFertig! Insgesamt wurden {total_replacements} Spaghetti-Code-Blöcke entfernt.")

if __name__ == '__main__':
    main()