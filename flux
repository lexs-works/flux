#!/usr/bin/env zsh

# flux - static site generator for engineering reference
# Uses ONLY ed and awk. HTML comments as markers: <!-- FLUX_* -->
# by ax-hack (Lex's Works · Engineering Workshop)
# 06.2026

set -e

# Конфигурация
SITE_TITLE="Engineering Reference · Lex's Works"
SITE_URL="https://guide.lexs.work"
ASSETS_DIR="assets"
BUILD_DIR="build"
TEMPLATES_DIR="templates"
SRC_DIR="src"

# Флаги
FORCE=0
CLEAN=0
COMPONENT=""
DEBUG=0

# Цвета
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    GREEN=''; BLUE=''; RED=''; YELLOW=''; NC=''
fi

debug_log() {
    if [[ $DEBUG -eq 1 ]]; then
        echo >&2 "${YELLOW}DEBUG: $1${NC}"
    fi
}

# Разбор аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        --force) FORCE=1 ;;
        --clean) CLEAN=1 ;;
        --component) COMPONENT="$2"; shift ;;
        --debug) DEBUG=1 ;;
        --help)
            echo "Usage: ./flux [OPTIONS]"
            echo "  --force            rebuild all"
            echo "  --clean            remove build/"
            echo "  --component NAME   build single component"
            echo "  --debug            enable verbose output"
            exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

if [[ $CLEAN -eq 1 ]]; then
    echo "→ Cleaning build directory..."
    rm -rf $BUILD_DIR
fi

mkdir -p $BUILD_DIR/{components,soldering,assembly,tools,assets}
if [[ -d "$ASSETS_DIR" ]]; then
    cp -r $ASSETS_DIR/* $BUILD_DIR/assets/ 2>/dev/null || true
fi

# Функция: генерация таблицы из CSV
generate_table() {
    local csv_file=$1
    local tmp_file=$2
    
    awk -F',' '
    BEGIN {
        print "<table class=\"component-table\">"
        print "<thead>"
        print "<tr><th>Marking / Code</th><th>Value</th><th>Package</th><th>Notes</th></tr>"
        print "</thead>"
        print "<tbody>"
    }
    NR > 1 {
        gsub(/^[ \t]+|[ \t]+$/, "", $1)
        gsub(/^[ \t]+|[ \t]+$/, "", $2)
        gsub(/^[ \t]+|[ \t]+$/, "", $3)
        gsub(/^[ \t]+|[ \t]+$/, "", $4)
        printf "      <tr>\n"
        printf "        <td class=\"param\">%s<\/td>\n", $1
        printf "        <td>%s<\/td>\n", $2
        printf "        <td>%s<\/td>\n", $3
        printf "        <td>%s<\/td>\n", $4
        printf "       <\/tr>\n"
    }
    END {
        print "</tbody>"
        print "</table>"
    }' "$csv_file" > "$tmp_file"
    
    debug_log "Table generated: $csv_file -> $tmp_file"
}

# Функция: Markdown → HTML
markdown_to_html() {
    local md_file=$1
    local tmp_file=$2
    
    awk '
    BEGIN { in_code = 0 }
    /^```/ {
        if (in_code) { print "</pre></code>"; in_code = 0 }
        else { print "<pre><code>"; in_code = 1 }
        next
    }
    in_code {
        print $0
        next
    }
    /^# /  { print "<h1>" substr($0, 3) "</h1>"; next }
    /^## / { print "<h2>" substr($0, 4) "</h2>"; next }
    /^### / { print "<h3>" substr($0, 5) "</h3>"; next }
    /^$/    { print ""; next }
    {
        if ($0 ~ /^- /) {
            sub(/^- /, "")
            print "<li>" $0 "</li>"
        } else if ($0 ~ /^[0-9]+\. /) {
            sub(/^[0-9]+\. /, "")
            print "<li>" $0 "</li>"
        } else {
            print "<p>" $0 "</p>"
        }
    }' "$md_file" > "$tmp_file"
    
    debug_log "Markdown converted: $md_file -> $tmp_file"
}

# Функция: генерация sidebar
generate_sidebar() {
    local current="$1"
    local tmp_file="/tmp/flux_sidebar_$$.html"
    
    cat > "$tmp_file" <<EOF
<aside class="sidebar">
    <h4>Components</h4>
    <ul>
        <li><a href="/components/resistors.html"$( [[ "$current" == "resistors" ]] && echo ' class="active"')>Resistors</a></li>
        <li><a href="/components/capacitors.html"$( [[ "$current" == "capacitors" ]] && echo ' class="active"')>Capacitors</a></li>
        <li><a href="/components/transistors.html">Transistors (soon)</a></li>
    </ul>
    <h4 style="margin-top: 1.5rem;">Soldering</h4>
    <ul>
        <li><a href="/soldering/smd.html">SMD Hand Soldering</a></li>
    </ul>
    <h4 style="margin-top: 1.5rem;">Assembly</h4>
    <ul>
        <li><a href="/assembly/thermal.html">Thermal Management</a></li>
    </ul>
</aside>
EOF
    
    echo "$tmp_file"
}

# Функция: генерация страницы через ed
generate_page() {
    local template=$1
    local output=$2
    local title=$3
    local description=$4
    local content_file=$5
    local sidebar_file=$6
    
    debug_log "Generating $output"
    debug_log "  template: $template"
    debug_log "  title: $title"
    debug_log "  content_file: $content_file"
    debug_log "  sidebar_file: $sidebar_file"
    
    # Копируем шаблон
    cp "$template" "$output"
    
    # Экранируем title и description для ed (только / и &)
    local title_esc=$(echo "$title" | sed 's/[\/&]/\\&/g')
    local desc_esc=$(echo "$description" | sed 's/[\/&]/\\&/g')
    
    # Создаём ed-скрипт
    local ed_script="/tmp/flux_ed_$$.ed"
    
    # Начинаем скрипт
    echo "/<!-- FLUX_TITLE -->/s//$title_esc/" > "$ed_script"
    echo "/<!-- FLUX_DESC -->/s//$desc_esc/" >> "$ed_script"
    echo "/<!-- FLUX_CONTENT -->/r $content_file" >> "$ed_script"
    echo "/<!-- FLUX_CONTENT -->/d" >> "$ed_script"
    
    if [[ -n "$sidebar_file" && -f "$sidebar_file" ]]; then
        echo "/<!-- FLUX_SIDEBAR -->/r $sidebar_file" >> "$ed_script"
        echo "/<!-- FLUX_SIDEBAR -->/d" >> "$ed_script"
    fi
    
    echo "w" >> "$ed_script"
    echo "q" >> "$ed_script"
    
    debug_log "ed_script: $ed_script"
    if [[ $DEBUG -eq 1 ]]; then
        echo "--- ed script content ---"
        cat "$ed_script"
        echo "--- end ed script ---"
    fi
    
    # Выполняем ed
    if ed -s "$output" < "$ed_script" 2>&1; then
        debug_log "ed completed successfully"
    else
        local ed_exit=$?
        echo "${RED}ERROR: ed failed with exit code $ed_exit${NC}"
        debug_log "ed script was:"
        cat "$ed_script"
        return 1
    fi
    
    rm -f "$ed_script"
    debug_log "Generated: $output"
}

# Сборка компонентов
build_components() {
    echo "${BLUE}→ Building components...${NC}"
    
    if [[ ! -d "$SRC_DIR/components" ]]; then
        echo "  No components found in $SRC_DIR/components"
        return
    fi
    
    local component_list=""
    
    for md in $SRC_DIR/components/*.md; do
        [[ -f "$md" ]] || continue
        local name=$(basename "$md" .md)
        local csv="$SRC_DIR/components/${name}.csv"
        local output="$BUILD_DIR/components/${name}.html"
        
        if [[ -f "$output" && $FORCE -eq 0 ]]; then
            echo "  - $name (skipped, use --force)"
            component_list+="      <li><a href=\"/components/${name}.html\">$name</a></li>\n"
            continue
        fi
        
        # Временные файлы
        local content_tmp="/tmp/flux_content_$$.html"
        local sidebar_tmp=""
        
        # Конвертируем Markdown
        markdown_to_html "$md" "$content_tmp"
        
        # Добавляем таблицу, если есть CSV
        if [[ -f "$csv" ]]; then
            local table_tmp="/tmp/flux_table_$$.html"
            generate_table "$csv" "$table_tmp"
            echo "<h2>Specifications</h2>" >> "$content_tmp"
            cat "$table_tmp" >> "$content_tmp"
            rm -f "$table_tmp"
        fi
        
        # Заголовок из первого h1
        local title=$(grep -m1 '^# ' "$md" | sed 's/^# //')
        [[ -z "$title" ]] && title="$name"
        
        local description="Reference on $name — specifications, packages, applications."
        
        # Генерируем sidebar
        sidebar_tmp=$(generate_sidebar "$name")
        
        # Собираем страницу
        generate_page "$TEMPLATES_DIR/component.html" "$output" "$title" "$description" "$content_tmp" "$sidebar_tmp"
        
        # Чистим
        rm -f "$content_tmp" "$sidebar_tmp"
        
        component_list+="      <li><a href=\"/components/${name}.html\">$title</a></li>\n"
        echo "  ✓ $name → ${output}"
    done
    
    echo "$component_list" > /tmp/flux_component_list.$$
}

# Сборка soldering
build_soldering() {
    echo "${BLUE}→ Building soldering guides...${NC}"
    
    if [[ ! -d "$SRC_DIR/soldering" ]]; then
        echo "  No soldering guides found"
        return
    fi
    
    for md in $SRC_DIR/soldering/*.md; do
        [[ -f "$md" ]] || continue
        local name=$(basename "$md" .md)
        local output="$BUILD_DIR/soldering/${name}.html"
        
        if [[ -f "$output" && $FORCE -eq 0 ]]; then
            echo "  - $name (skipped, use --force)"
            continue
        fi
        
        local content_tmp="/tmp/flux_content_$$.html"
        markdown_to_html "$md" "$content_tmp"
        
        local title=$(grep -m1 '^# ' "$md" | sed 's/^# //')
        [[ -z "$title" ]] && title="$name"
        
        generate_page "$TEMPLATES_DIR/page.html" "$output" "$title" "Guide on $title" "$content_tmp" ""
        
        rm -f "$content_tmp"
        echo "  ✓ $name → ${output}"
    done
}

# Сборка assembly
build_assembly() {
    echo "${BLUE}→ Building assembly guides...${NC}"
    
    if [[ ! -d "$SRC_DIR/assembly" ]]; then
        echo "  No assembly guides found"
        return
    fi
    
    for md in $SRC_DIR/assembly/*.md; do
        [[ -f "$md" ]] || continue
        local name=$(basename "$md" .md)
        local output="$BUILD_DIR/assembly/${name}.html"
        
        if [[ -f "$output" && $FORCE -eq 0 ]]; then
            echo "  - $name (skipped, use --force)"
            continue
        fi
        
        local content_tmp="/tmp/flux_content_$$.html"
        markdown_to_html "$md" "$content_tmp"
        
        local title=$(grep -m1 '^# ' "$md" | sed 's/^# //')
        [[ -z "$title" ]] && title="$name"
        
        generate_page "$TEMPLATES_DIR/page.html" "$output" "$title" "Guide on $title" "$content_tmp" ""
        
        rm -f "$content_tmp"
        echo "  ✓ $name → ${output}"
    done
}

# Сборка главной страницы
build_index() {
    echo "${BLUE}→ Building index...${NC}"
    
    local component_list=$(cat /tmp/flux_component_list.$$ 2>/dev/null || echo "<li>No components yet</li>")
    
    local content_tmp="/tmp/flux_index_content_$$.html"
    
    cat > "$content_tmp" <<EOF
<div class="hero">
    <h1>Engineering Reference</h1>
    <p class="subhead">Components, soldering techniques, system assembly — a technical handbook for engineers, by an engineer.</p>
</div>

<div class="categories">
    <h2>Electronic Components</h2>
    <div class="category-grid">
        <ul class="component-list">
$component_list
        </ul>
    </div>
</div>

<div class="categories">
    <h2>Soldering Techniques</h2>
    <div class="category-grid">
        <ul>
            <li><a href="/soldering/smd.html">SMD Hand Soldering</a></li>
        </ul>
    </div>
</div>

<div class="categories">
    <h2>Assembly</h2>
    <div class="category-grid">
        <ul>
            <li><a href="/assembly/thermal.html">Thermal Management</a></li>
        </ul>
    </div>
</div>
EOF
    
    generate_page "$TEMPLATES_DIR/page.html" "$BUILD_DIR/index.html" \
        "Engineering Reference · Lex's Works" \
        "Technical reference on electronic components, soldering, and assembly." \
        "$content_tmp" ""
    
    rm -f "$content_tmp"
    echo "  ✓ index.html"
}

# Если указан конкретный компонент
if [[ -n "$COMPONENT" ]]; then
    echo "${GREEN}→ Building single component: $COMPONENT${NC}"
    FORCE=1
    build_components
    exit 0
fi

# Полная сборка
echo "${GREEN}flux — static site generator${NC}"
echo ""

build_components
build_soldering
build_assembly
build_index

echo ""
echo "${GREEN}✅ Done! Site built in $BUILD_DIR/${NC}"
echo ""
echo "  To preview: cd $BUILD_DIR && python3 -m http.server 8000"