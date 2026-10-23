# install

I lives in `~/.emacs.d`

## dependency packages(binaries)




```
xclip

rtags

ripgrep

```

###
```
quicklisp


curl -O /tmp/quicklisp.lisp https://beta.quicklisp.org/quicklisp.lisp
sbcl --load /tmp/quicklisp.lisp
* (quicklisp-quickstart:install)
* (ql:add-to-init-file)


```

### clhs docs


```
But we can also browse it offline from Emacs. We have to install a CL package and to configure the Emacs side with one command:

# start sbcl

sbcl

(ql:quickload "clhs")
(clhs:install-clhs-use-local)

# Then add this to your Emacs configuration:

(load "~/.quicklisp/clhs-use-local.el" 'noerror)

```

### rtags

if use rtags to index C/C++ projects:

```
yay -Sy rtags


# SEE https://github.com/Andersbakken/rtags#tldr-quickstart
/bin/rdm &
/bin/rc -J .
```

### download jars for java


```
mkdir -p ~/.emacs.d/.local/cache/language-server/java/bundles
mkdir -p ~/.emacs.d/.local/cache/lombok


# decompiler
cd ~/.emacs.d/.local/cache/language-server/java/bundles

wget https://raw.githubusercontent.com/sekirocc/vscode-java-decompiler/master/server/dg.jdt.ls.decompiler.common-0.0.3.jar
wget https://raw.githubusercontent.com/sekirocc/vscode-java-decompiler/master/server/dg.jdt.ls.decompiler.fernflower-0.0.3.jar


# lombok
cd ~/.emacs.d/.local/cache/lombok
wget https://projectlombok.org/downloads/lombok.jar

# or just in emacs, and call function:

lsp-java-lombok-init


# jdtls

mkdir -p ~/.local/share/jdtls
wget https://download.eclipse.org/jdtls/milestones/1.9.0/jdt-language-server-1.9.0-202203031534.tar.gz
tar zxvf jdt-language-server-1.9.0-202203031534.tar.gz -C ~/.local/share/jdtls
sudo ln -s ~/.local/share/jdtls/bin/jdtls /usr/local/bin/jdtls

# test jdtls
jdtls
```


### python

```
brew install autopep8
```



### hack
hack `elpa/treemacs-20240229.2108/treemacs-rendering.el` (function `treemacs--create-file-button-strings`) for alignment

```
      ;; hack by sekirocc. for icon alignment
      (format "%s%s" (if (display-graphic-p) treemacs-nerd-icons-tab "") (treemacs-icon-for-file ,path))

```
