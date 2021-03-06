# logview: 文本日志查看分析插件

## 背景简介

想到写这个插件的缘由，是日常工作中经常有查看、分析日志的需求。可能最先想到用的
工具就是 less 与 grep 吧——当然，这是指 unix 类服务器环境下而言。

vim 是文本编辑器。若日志文件并不巨大，直接用 vim 打开日志进行浏览查找也是方便
的。但若日志文件太大，vim 打开之要全部载入内存，就未必合适了。而且对于日志，一
般来说没必要全部打开，一个时刻应该是提取关注其中一部分内容。所以其工作模式常常
是 `grep file | less` ，对于有“猫”神信仰的玩家，可能更喜欢 `cat file | grep
| less` 的写法。

less 是个很好的查看器，一些快捷键也与 vim 习惯相符。但由于没有编辑功能，对日志
输入的二次分析提取略有不足。所以我想要的功能，是把日志（或任意有限文本输出）放
到 vim 环境中，同时也可利用 shell 命令提取与再提取日志文本。

目前，本插件预设提供的主要功能有：

* 打开常规日志文件如 `*.log` `*.error` 时，自动设为只读，防误修改日志原件。
* 提供一种临时的分析提取日志的 buff 文件类型，在这里可直接输入 shell 命令，并
  展示结果，而且尽可能要方便地编辑命令与选取结果文本。

虽然这第二点的功能导向的最终结果，好像是要支持在一个 vim buff 内运行 shell 命
令，但这无意于在 vim 中内置一个 shell ，这不是一个小插件能做的事（当然我曾经好
像是见过一些 vimer 中的高级玩家写的插件力求在 vim 窗口中模拟一个 shell），甚至
也不是 vim 所应做的事。如果真有必要用 shell 管理事务时，用 `Ctrl-Z` 回到父
shell 进程或 `:shell` 打开一个 shell 子进程都是更好的选择。

所以，在这个插件内运行的命令（甚至是 vim 命令行调用的 ! 外部命令），都建议只在
关注命令的文本输出结果，并需要捕获该结果时使用。当然，这也是用户的自由。

## 日志分析文件类型 `*.lg`

因为这不宜影响改全局的 vim 编辑方式，所以这应该做成一个局部的文件类型插件。提
倡一种文件类型后缀也是件麻烦事，所以就偷懒暂定后缀名为 `lg` 吧。

这种文件类型约定有以下特殊或格式：

* 以星号 `#` 或美元符号 `$` 开头的行，认为是 shell 命令，将包装调用 vim 的 `r
  !shell-command`，该命令会先将 shell 命令的输出结果保存至临时文件时，再读入当
  前 buff 。
* 在 `#$` 命令行下面，会额外增加两行标记行，分别添加在输出结果的起始与结尾处。

```
=========================================================================== <<
（中间是外部命令输出结果行）
.
```

起始行是 75 个等号外加一个空格及两个 `<<` 符号，结尾行就一个点 `.` 而已。长等
号行既用于视觉分割效果，也可认为是等号含义，因为 `<<` 与 `.` 相当于块引用。

命令行与其输出一起，整体当作一个段落，算是 `.lg` 文件的主要格式运用了。然而也
顺带支持其他一些格式。

* 以冒号 `:` 开头的行，当作是 vim 的命令行，直接按 vimL 语义运行。
* 以百分号 `%` 开头的行，当作是简单的数学运算，包装调用为 vim 的 `echo <exp>`
  命令。
* 其他不在等号与点号中间的行，当作普通的文本文件，可随意当作草稿输入编辑。

## 文件夹类型插件功能 ftplugin/

### 文件区块移动 normal mation

* `[[` 光标移到上一行命令行开始，略过前导 `:#$%` 符号，定位于其行内第一个单词
  位置上。
* `]]` 光标移到下一行命令行开始。
* `[=` `]=` 分别移动到上（下）一行等号行，即输出开始行。
* `[.` `].` 分别移动到上（下）一行点号行，即输出结束行。
* `v=` `d=` 'c=' 'zf=' 操作后缀的 `=` 文本对象定义为所在的所有输出行，如果当前
  光标位于等号行或点号行边界，则包括两行边界行（类似 a{）；如果当前光标在中间
  某行，则选定操作部分仅包括命令输出结果行，不包括上下两行边界（类似 i}）效果
  。

折叠模式建议手动。

### 命令行运行快捷键

* 在有 `:#$%` 符号标记的命令行上按回车运行当前命令，目前只捕获 `#$` shell 命令
  的输出，将其添加到命令行下面。如果当前命令行下面本来就有等号与点号标记的输出
  块，则替换原输出结果。
* 在插入模式下也可直接按回车运行，如果不在能识别的命令行上，可照旧插入回车符换
  行。
* vim 本身的命令行，提供一个 `READ` 命令（`read`大写版），其参数当作外部 shell
  命令字符串。`READ` 命令将其后参数添加到当前文件 buff 最末尾，然后像按回车一
  样运行该行 shell 命令，捕获输出。
* 命令行模式下的快捷键 `<C-G>`（可定制）可将 `!shell-command`
  `r !shell-command` `r file` 这几种命令自动转换为 `READ` 命令调用。

虽然文件内的 `#$` 命令行可直接编辑，但 vim 的 Ex 命令行模式可能提供更方便的补
全，可利用之再转换添加到文件中。

输出结果默认情况下是当前 buff 的当前命令行下一行，但若在命令行末尾添加重定向
`>` 或 `>>` 符号时，可将结果捕获至其他 vim buff 窗口。支持的目标参数有：

* `>b` 默认，即当前 buff
* `>w` 当前窗口，但新建 buff
* `>s` 水平分割窗口
* `>v` 垂直分割窗口
* `>t` 在新建标签页上

`[wsvt]` 参数之后可指定文件名，如 `>tfile.lg` 表示在新标签页打开名为 `file.lg`
的文件以捕获输出。若不指定文件名，则自动按编号 `1.lg` `2.lg` 生成文件名。如果
原文件名恰好存在，则 `>` 覆盖，而 `>>` 添加到文件末尾。

另注：将结果重定向其他 buff 时，首先也会将当前命令行拷过去，然后在其下方输出结
果。

### 命令行编辑便用键

这节介绍的快捷键，一般只用于有 `:#$%` 前缀的命令行，在其他普通行无特殊意义。

* `H` `L` (normal) 分别移动到命令行首行末，在输出区块也生效，会跳到其上方的命
  令行相应位置处，且“行首”不包括 `:#$%` 前缀符号及可能的后缀空格。
* `I` `A` (normal) 在行首或行尾进入插入模式。
* `o` `O` (normal) 在当前区段下方或上方打开一个新的命令行，自动插入最近用过的
  命令前缀符号。
* `o` (Insert) 在行首插入时可智能地导入上次运行的命令，其他位置可正常输入字母
  表 `o`
* `<C-A>` `<C-U>` (Insert) 插入模式下移动到行首，或清空当前行，都不包括前缀符
  号。`<C-E>` 至行尾， `<C-K>` 删至行尾（这两个 imap 在我的全局 vimrc 就简单定
  义了，这里没重复添加）

本插入特意强化管道链式命令行的编辑功能。

* `|` (normal) 移动到下一个管道处，行内首尾循环，可带数字前缀直接跳到该行第几
  个管道处。
* `|` (visual/operator) 定义为文本对象，选择或操作当前管道部分。
* `|` (Insert) 行首输入时自动往前搜索复制前行命令，并在后面添加 '|' 字符，行尾
  重复输入 '|' 时往前删除一个管道部分，其他情况可正常输入 '|' 字符。

* `<C-P>` `<C-N>` (Insert) 往前（后）搜索命令行。

其他：

* `yy` (normal) 将当前命令行复制到文件末尾，并跳到文件末尾。
* `<C-T>` (Insert) 切换当前行的前缀命令符号。

前缀命令符号可按 vim 正常编辑命令删除，如此则使该行变成普通行。

### 输出结果块内操作

在输出结果区域内，提供几个快捷键用于重组命令。

* `gr` 在当前命令后面添加管道命令，搜索 (grep) 光标下方的单词。
* `gR` 当前命令的最后一个管道，替换为搜索 (grep) 光标下方的单词。

注：这两映射目前只生成命令，放于当前块下方，要实际运行输出还得再敲一个回车。

* `:PipeGrep` 自定义命令，可手动提供其他参数。`gr` `gR` 映射实际也调用该命令。

* `gF` 使用 cat 命令将光标下的文件打开一个新 tab 中。推荐用 cat 的原因是可继续
  添加管道链命令。

## 其他补充功能

* 草稿文件 `:e -n.lg` 若文件名是以负号开始负整数，会将该 buff 设为不可写的草稿
  buff，可以随意输入一些文本及可运行命令。因为常规文件不推荐使用 `-` 开始的文
  件名，所以用此文件名激活这种文件类型插件。

以下是可能的 TODO:

* 语法颜色，语法折叠，这在大文件下可能影响性能流畅的
* 命令行输入补全

## 注意事项

* 对 shell 命令只进行了简单的包装调用，自行负责命令的安全性。
* 按 vim 默认的 `r !` 运行方式，若有错误，也会显示错误信息。
* 不建议使用不以文本输出为目的命令，如 mkdir, rm 等，但 ls 可能是有意义的。

## 定制使用

插件功能都写在 `autoload/` 目录下。`ftplugin/dmlog.vim` 提供一个文件类型插件。
因为 `log` 可能易重名，故随意加了个前缀。

该文件类型插件，主要是大量键映射 `map` 命令，及少量自定义命令。几乎是用户操作
接口，对不喜欢或有冲突的键映射可直接改，或另存一个 `setlocal.vim` 。
