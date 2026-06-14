![flux · IN DEVELOPMENT](https://img.shields.io/badge/flux-WIP-c8a86b?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyMCIgaGVpZ2h0PSIyMCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiNjOGE4NmIiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48Y2lyY2xlIGN4PSIxMiIgY3k9IjEyIiByPSIxMCIvPjxwYXRoIGQ9Ik0xMiA4djRsMiAyIi8+PC9zdmc+)

# flux

[English (GB)](#english) · [Русский](#русский)

**flux** — static site generator for engineering reference.  
Built with `sh` + `awk` + `ed`. No dependencies. No AI. No bullshit.

---

## English

### What is it?

`flux` turns Markdown files and CSV tables into a clean HTML reference site.  
It uses only POSIX tools — no Python, no Node, no Ruby.

### Features

- Markdown → HTML (headings, lists, code blocks)
- CSV → HTML tables
- HTML templates with `<!-- FLUX_TITLE -->`, `<!-- FLUX_CONTENT -->` markers
- Sidebar injection via `ed`
- Incremental builds (`--force` to rebuild all)
- Single component rebuild (`--component resistors`)

### Quick start

```bash
git clone https://github.com/lexs-works/flux.git
cd flux

# Build the site
./flux

# Full rebuild
./flux --force

# Build only one component
./flux --component resistors

# Clean build directory
./flux --clean

# Preview locally
cd build && python3 -m http.server 8000
```
Project structure
```text
flux/
├── flux                 # the generator itself
├── src/
│   ├── components/      # .md + .csv files
│   ├── soldering/       # .md guides
│   └── assembly/        # .md guides
├── templates/
│   ├── component.html   # template with sidebar
│   └── page.html        # template without sidebar
├── assets/              # CSS, images, favicon
└── build/               # generated site
```

Example: component.md
```markdown
# Resistors

The most fundamental component — understanding resistor types, codes, and applications separates a parts assembler from an engineer.
```

Example: component.csv
```csv
Marking,Value,Package,Notes
101,100Ω,0603,3-digit: 10×10¹
472,4.7kΩ,0805,47×10²
1002,10kΩ,1206,4-digit: 100×10²
```

### Requirements

- sh (Pure Bourne Shell)
- awk (any POSIX version)
- ed (standard UNIX editor)

### Philosophy
One tool, one job.

- ed manipulates text 
- awk parses data
- no frameworks
- no package managers

### License
MIT — do whatever you want, just keep the original author's name.

## Русский

**flux** — генератор статических страниц для технического справочника.
Превращает Markdown и CSV в чистый HTML. Только sh + awk + ed. Никаких зависимостей.

### Возможности
- Markdown → HTML (заголовки, списки, блоки кода)
- CSV → HTML таблицы
- Шаблоны с маркерами ```<!-- FLUX_TITLE -->```, ```<!-- FLUX_CONTENT -->```
- Подстановка бокового меню через ed
- Инкрементальная сборка (--force для полной перегенерации)
- Сборка одного компонента (--component resistors)

### Быстрый старт

```bash
git clone https://github.com/lexs-works/flux.git
cd flux

# Собрать сайт
./flux

# Полная пересборка
./flux --force

# Собрать только resistors
./flux --component resistors

# Очистить build/
./flux --clean

# Локальный просмотр
cd build && python3 -m http.server 8000
```

### Структура проекта

```text
flux/
├── flux                 # сам генератор
├── src/
│   ├── components/      # .md + .csv файлы
│   ├── soldering/       # руководства по пайке
│   └── assembly/        # руководства по сборке
├── templates/
│   ├── component.html   # шаблон с боковым меню
│   └── page.html        # шаблон без меню
├── assets/              # CSS, картинки, фавикон
└── build/               # сгенерированный сайт
```

Пример: component.md
```markdown
# Резисторы

Самый фундаментальный компонент — понимание типов резисторов, кодов и областей применения отличает инженера от сборщика.
```

Пример: component.csv
```csv
Маркировка,Значение,Корпус,Примечания
101,100Ω,0603,3-значный: 10×10¹
472,4.7kΩ,0805,47×10²
1002,10kΩ,1206,4-значный: 100×10²
```

### Зависимости

- sh (чистый Bourne Shell)
- awk (любая POSIX-версия)
- ed (стандартный редактор UNIX)

### Философия

Один инструмент — одна задача.

- ed правит текст
- awk парсит данные
- Никаких фреймворков
- Никаких package.json

### Лицензия

MIT — делайте что хотите, просто оставьте имя автора.