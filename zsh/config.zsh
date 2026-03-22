# export TERM=xterm-24bit

# 确保历史记录追加到文件而不是覆盖
setopt APPEND_HISTORY
# 每次执行命令后立即将其写入历史记录文件
setopt INC_APPEND_HISTORY
# 允许多个终端会话共享历史记录
setopt SHARE_HISTORY
# 增大历史记录大小
HISTSIZE=10000
SAVEHIST=20000
# 忽略重复的命令
setopt HIST_IGNORE_ALL_DUPS
# 忽略以空格开头的命令
setopt HIST_IGNORE_SPACE
# 忽略简单的命令（如 `ls`）
setopt HIST_NO_STORE

export GIT_PAGER=less

export EDITOR=nvim


alias vim="nvim"

if [ -f /Applications/Emacs.app/Contents/MacOS/Emacs ]; then
    alias em="/Applications/Emacs.app/Contents/MacOS/Emacs -nw"
    alias ee="/Applications/Emacs.app/Contents/MacOS/Emacs"
else
    alias em="/usr/local/bin/emacs -nw"
    alias ee="/usr/local/bin/emacs"
fi

alias emc="emacsclient"


jdk() {
        version=$1
        if [ -f /usr/libexec/java_home ]; then
            export JAVA_HOME=$(/usr/libexec/java_home -v"$version");
        fi
        java -version
}
jdk 21

kl() {
    echo -ne "\e[2 q"
}

ki() {
    echo -ne "\e[6 q"
}

kk() {
    tmux send-keys -R \; clear-history
}

hs() {
    hub sync
}

cl() {
    claude --permission-mode  bypassPermissions
}

loadconda(){
    source /opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh
}

export DEVLOG="$HOME/work/code/cpp/dev/"
export CODEDIR="$HOME/work/code"
ssp() {
    local my_curr_dir=$(basename "$PWD")
    local my_logdev_dir="${DEVLOG}/cursor_chats/${my_curr_dir}"
    # 创建目标目录
    mkdir -p "$my_logdev_dir"
    # 检查 .specstory/history 是否存在
    if [ ! -d ".specstory/history" ]; then
        echo "Error: .specstory/history directory does not exist."
        return 1
    fi
    for i in $(ls ".specstory/history/"); do
        cp "$(pwd)/.specstory/history/$i" "${my_logdev_dir}/$i" || true
    done
}


if [ -f /usr/bin/fdfind ]; then
    alias fd=/usr/bin/fdfind
fi

sssp () {
    (
        # 切换到 DEVLOG 目录
        cd "$DEVLOG" || { echo "Failed to switch to $DEVLOG"; return 1; }

        # 确保 $DEVLOG 是一个 Git 仓库
        if [[ ! -d "$DEVLOG/.git" ]]; then
            echo "Error: $DEVLOG is not a valid Git repository."
            return 1
        fi

        # 记录当前分支名称
        local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null) || {
            echo "Failed to determine current branch."
            return 1
        }

        # 记录当前目录和分支信息
        local my_logdev_dir="${DEVLOG}/cursor_chats"

        # 确保目标目录存在
        mkdir -p "$my_logdev_dir"

        # 捕获退出信号，确保清理逻辑被执行
        trap 'cleanup' EXIT

        # 清理函数：回到原始分支并删除所有拷贝的内容
        cleanup() {
            echo "Cleaning up..."

            # 如果有未提交的修改，恢复原始状态
            if [[ $(git status --porcelain) ]]; then
                echo "Discarding all uncommitted changes..."
                git reset --hard HEAD || echo "Failed to reset changes."
                git clean -fd || echo "Failed to clean untracked files."
            fi

            # 切换回原始分支
            if [[ -n "$current_branch" ]]; then
                echo "Switching back to original branch: $current_branch"
                git checkout "$current_branch" || echo "Failed to switch back to original branch."
            fi

            # 如果之前有 stash，恢复它
            if [[ $(git stash list | grep "Before ssp operation") ]]; then
                echo "Applying stashed changes..."
                git stash pop || {
                    echo "Failed to apply stashed changes."
                    return 1
                }
            else
                echo "No stashed changes to apply."
            fi
        }


        # 使用 fd 查找所有 .specstory 目录
        echo "Finding all .specstory directories..."
        specstory_dirs=$(fd '.specstory' "${CODEDIR}" -t d -d 4 --no-ignore --hidden)

        # 检查是否找到任何 .specstory 目录
        if [[ -z "$specstory_dirs" ]]; then
            echo "Warning: No .specstory directories found. Skipping file copy."
        fi

        # 如果有未提交的修改，先 stash 它们
        if [[ $(git status --porcelain) ]]; then
            echo "Stashing local changes..."
            git stash push -m "Before ssp operation" || {
                echo "Failed to stash local changes."
                return 1
            }
        else
            echo "No local changes to stash."
        fi

        # 切换到 ssp 分支
        echo "Switching to ssp branch..."
        git checkout ssp || {
            echo "Failed to switch to ssp branch."
            return 1
        }
        git pull origin ssp

        # 遍历每个找到的 .specstory/history 目录并复制文件
        echo "Copying files from found .specstory/history directories..."
        while IFS= read -r specstory_dir; do
            repo_name=$(basename "$(dirname "$specstory_dir")")
            mkdir -p "${my_logdev_dir}/$repo_name"
            echo "Processing repository: $repo_name"

            history_dir="$specstory_dir/history"
            if [ -d "$history_dir" ]; then
                echo "Processing $history_dir..."
                for file_path in $(ls -A "$history_dir" 2>/dev/null); do
                    if [[ -f "$history_dir/$file_path" ]]; then
                        echo "Copying file: $history_dir/$file_path -> ${my_logdev_dir}/$repo_name/$file_path"
                        cp "$history_dir/$file_path" "${my_logdev_dir}/$repo_name/$file_path" || true
                    fi
                done
            else
                echo "Skipping $specstory_dir: no history directory found."
            fi

            # if [ -d "$history_dir" ]; then
            #     echo "Processing $history_dir..."
            #     for file_path in "$history_dir"/*; do
            #         if [[ -f "$file_path" ]]; then
            #             echo "Copying file: $file_path -> ${my_logdev_dir}/$repo_name/$(basename "$file_path")"
            #             cp "$file_path" "${my_logdev_dir}/$repo_name/$(basename "$file_path")" || true
            #         fi
            #     done
            # else
            #     echo "Skipping $specstory_dir: no history directory found."
            # fi

        done <<< "$specstory_dirs"

        # 添加文件到 git 并提交
        echo "Committing changes..."
        git add -A && git commit -m "update" || {
            echo "Failed to commit changes."
            return 1
        }

        # 推送分支到远程仓库
        echo "Pushing changes to origin/ssp..."
        git push origin ssp || {
            echo "Failed to push changes."
            return 1
        }

        echo "Operation completed successfully."
    )
}


#
# Emacs vterm quick command
#

vterm_printf() {
    if [ -n "$TMUX" ] \
           && { [ "${TERM%%-*}" = "tmux" ] \
					|| [ "${TERM%%-*}" = "screen" ]; }; then
        # Tell tmux to pass the escape sequences through
        printf "\ePtmux;\e\e]%s\007\e\\" "$1"
    elif [ "${TERM%%-*}" = "screen" ]; then
        # GNU screen (screen, screen-256color, screen-256color-bce)
        printf "\eP\e]%s\007\e\\" "$1"
    else
        printf "\e]%s\e\\" "$1"
    fi
}


vterm_cmd() {
    local vterm_elisp
    vterm_elisp=""
    while [ $# -gt 0 ]; do
        vterm_elisp="$vterm_elisp""$(printf '"%s" ' "$(printf "%s" "$1" | sed -e 's|\\|\\\\|g' -e 's|"|\\"|g')")"
        shift
    done
    vterm_printf "51;E$vterm_elisp"
}

find_file() {
    vterm_cmd find-file "$(realpath "${@:-.}")"
}


dotenv () {
    set -a

    local env_file="$(pwd)/.env"

    if [ -f "$env_file" ]; then
        . "$env_file"
    fi

    set +a
}

set_proxy() {
    export http_proxy=http://127.0.0.1:9910;
    export https_proxy=${http_proxy};
    export HTTP_PROXY=${http_proxy};
    export HTTPS_PROXY=${http_proxy};
}

unset_proxy() {
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY;
}

#
# Emacs vterm quick command end
#




alias ss='swift sh'
alias sf='swiftformat'


export PATH="/opt/homebrew/bin:$PATH"

export GOPATH="$HOME/work/workspaces/go"
export PATH="$GOPATH/bin:$PATH"
export GOPROXY=https://goproxy.cn,direct

export PATH="$HOME/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"

export PATH="$HOME/zig/zls/bin:$PATH"
export PATH="$HOME/zig/zig-macos-aarch64:$PATH"
export PATH="$HOME/.roswell/bin:$PATH"
export PATH="$HOME/platform-tools:$PATH"

export VCPKG_ROOT="$HOME/vcpkg"


[ -f ~/perl5/perlbrew/etc/bashrc ] && source ~/perl5/perlbrew/etc/bashrc


[ -f ~/.doter/zsh/.git_aliases ] && source ~/.doter/zsh/.git_aliases


source <(fzf --zsh)

alias ffplay="ffplay -vf \"drawtext=text='%{pts\:hms}':x=10:y=10:fontsize=32:fontcolor=yellow:box=1:boxcolor=red@0.8:boxborderw=10\" "

if [ -f "$HOME/.claude/local/claude" ]; then
    alias claude="$HOME/.claude/local/claude"
fi
