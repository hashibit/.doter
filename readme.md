

## Install

```
mkdir -p ~/.config
cd ~

git clone https://github.com/sekirocc/.doter.git
cd .doter && git submodule update --init

ln -s ~/.doter/.emacs.d         ~/.emacs.d
ln -s ~/.doter/w3m              ~/.w3m
ln -s ~/.doter/idea/.ideavimrc  ~/.ideavimrc
ln -s ~/.doter/xcode/.xvimrc    ~/.xvimrc
ln -s ~/.doter/nvim             ~/.config/nvim
ln -s ~/.doter/tmux             ~/.config/tmux
ln -s ~/.doter/helix            ~/.config/helix
ln -s ~/.doter/wezterm          ~/.config/wezterm
ln -s ~/.doter/alacritty        ~/.config/alacritty
ln -s ~/.doter/ghostty          ~/.config/ghostty
ln -s ~/.doter/karabiner        ~/.config/karabiner
ln -s ~/.doter/kak              ~/.config/kak
ln -s ~/.doter/git              ~/.config/git
ln -s ~/.doter/sublime/User     ~/.config/sublime-text/Packages/User

mkdir -p ~/.tabby
cp ~/.doter/tabby/config.toml ~/.tabby/config.toml

```

#### common tools

```
sudo apt install silversearcher-ag
sudo apt install ripgrep
sudo apt install fd-find
sudo apt install xclip wl-clipboard
sudo apt install fonts-wqy-microhei


# some dev tools
sudo apt install flatpak
sudo apt install nodejs
sudo apt install apt-file
sudo apt install hub
sudo apt install ros
sudo apt install npm
sudo apt install golang
sudo apt install openjdk-21-jdk
sudo apt install mariadb-server
sudo apt install cmake
sudo apt install clang-19
sudo apt install htop
sudo apt install fonts-wqy-microhei
curl -LsSf https://astral.sh/uv/install.sh | sh
uv tool install basedpyright





# or macOS
brew install ripgrep ag fd
## language specific
brew install clojure clojure-lsp clojurescript


brew tap homebrew/cask-fonts
brew install --cask font-dejavu-sans-mono-nerd-font
brew install --cask font-source-code-pro-for-powerline

brew tap d12frosted/emacs-plus
brew install d12frosted/emacs-plus/emacs-plus@30
ln -s /opt/homebrew/opt/emacs-plus@30/Emacs.app /Applications
```

install epc, emacs/lisp/blink-search need this.
pip3 install epc  --break-system-packages


emacs in macOS, enlarge tooltip fonts.
```
defaults write org.gnu.Emacs NSToolTipsFontSize -int 16
```



#### emacs


```bash
# ubuntu
sudo apt install texinfo
sudo apt install libxpm-dev libjpeg-dev libgif-dev libtiff-dev libgnutls28-dev libpng-dev libtree-sitter-dev
sudo apt install build-essential libgtk-3-dev libgnutls28-dev \
    libncurses5-dev libxml2-dev libtiff5-dev libgif-dev libjpeg-dev \
    libpng-dev librsvg2-dev libm17n-dev libotf-dev libjansson-dev \
    libgccjit-12-dev texinfo autoconf libcairo2-dev

git clone --depth=1 https://github.com/emacs-mirror/emacs.git
cd emacs
./autogen.sh
./configure \
    --with-pgtk \
    --with-native-compilation=aot \
    --with-json \
    --with-cairo \
    --without-imagemagick \
    --without-x \
    --without-xaw3d \
    --prefix=/usr/local
make -j8
sudo make install


```

#### kak

make sure `python` command exists. if you only have `python3`, then make a link.
kakoune-easymotion need `python` to be present, or it will hung.

```
sudo ln -s /bin/python3 /bin/python
```

#### nvim

# install neovim
git clone https://github.com/neovim/neovim.git
cd neovim
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install

```

download patched-fonts

```
wget "https://github.com/ryanoasis/nerd-fonts/raw/refs/heads/master/patched-fonts/DejaVuSansMono/Regular/DejaVuSansMNerdFontMono-Regular.ttf"
wget "https://github.com/XuanXiaoming/Sarasa-Mono-SC-Nerd/raw/refs/heads/master/Sarasa-Mono-SC-Nerd.ttf"
```

#### tmux

install 24bit terminfo.

```
bash ~/.doter/.tmux/xterm-24bit.sh
```



#### backup

you may need to backup your old configs first.

```
mkdir -p ~/.dot_backup
cd ~

mv ~/.emacs.d           ~/.dot_backup
mv ~/.w3m               ~/.dot_backup
mv ~/.ideavimrc         ~/.dot_backup
mv ~/.xvimrc            ~/.dot_backup
mv ~/.config/nvim       ~/.dot_backup
mv ~/.config/tmux       ~/.dot_backup
mv ~/.config/helix      ~/.dot_backup
mv ~/.config/wezterm    ~/.dot_backup
mv ~/.config/alacritty  ~/.dot_backup
mv ~/.config/karabiner  ~/.dot_backup
mv ~/.config/kak        ~/.dot_backup
mv ~/.config/git        ~/.dot_backup
```
