#sed

原文http://coolshell.cn/articles/9104.html#comment-592073

个人总结

样例:
This is my cat
	my cat's name is betty

This is my dog
	my dog's name is frank

This is my fish
	my fish's name is george

This is my goat
	my goat's name is adam

----

`-i` 直接修改源文件

`-n` 不显示不匹配的行
	
	

`/s` 替换
	
	sed -i "s/my/your/g" file.txt
		/my 表示匹配my
		/your 表示替换为your 
		/g 一行上替换所有的匹配
	sed "s/^/addsth/g" file.txt
		每行开头增加内容
	sed "s/$/addsth/g" file.txt
	
	
例如去掉HTML中的tags:(正则表达式)
	
	sed 's/<[^>]*>//g' html.txt
		<开头 并且非>任意个 >结尾
		
`指定替换的内容`
	
	只替换指定范围的
		sed "3,6s/my/your/g" file.txt
	只替换每行的第一个s
		sed "s/s/S/1" file.txt
	只替换每行的第二个s
		sed "s/s/S/2" file.txt
	只替换每行第三个以后的s
		sed "s/s/S/3g"
		
`多个匹配`

	一次替换多个模式（第一个模式把第一行到第三行的my替换成your，第二个则把第3行以后的This替换成了That）
	
		sed "1,3s/my/your/g; 3,$s/This/That/g" file.txt
	
	等价于
		sed -e "1,3s/my/your/g' -e '3,$s/This/That/g" fiel.txt
		
		
可以`使用&来当做被匹配的变量`，然后可以在基本左右加点东西。如下所示：

		sed "s/my/[&]/g" file.txt
			This is [my] cat, [my] cat's name is betty



**`圆括号匹配`**

圆括号括起来的正则表达式所匹配的字符串会可以当成变量来使用，sed中使用的是\1,\2…
	
	 sed 's/This is my \([^,]*\),.*is \(.*\)/\1:\2/g' my.txt
	cat:betty
	dog:frank
	fish:george
	goat:adam
	上面这个例子中的正则表达式有点复杂，解开如下（去掉转义字符）：

	正则为：This is my ([^,]*),.*is (.*)
	匹配为：This is my (cat),……….is (betty)
	然后：\1就是cat，\2就是betty	


----

##sed命令

`N命令` ~~没看懂~~


把下一行的内容纳入当成缓冲区做匹配。

下面的的示例会把原文本中的偶数行纳入奇数行匹配，而s只匹配并替换一次，所以，就成了下面的结果：

	$ sed 'N;s/my/your/' pets.txt
	This is your cat
	  my cat's name is betty
	This is your dog
	  my dog's name is frank
	This is your fish
	  my fish's name is george
	This is your goat
	  my goat's name is adam
	也就是说，原来的文件成了：

	This is my cat\n  my cat's name is betty
	This is my dog\n  my dog's name is frank
	This is my fish\n  my fish's name is george
	This is my goat\n  my goat's name is adam
	这样一来，下面的例子你就明白了，
	$ sed 'N;s/\n/,/' pets.txt
	This is my cat,  my cat's name is betty
	This is my dog,  my dog's name is frank
	This is my fish,  my fish's name is george
	This is my goat,  my goat's name is adam

**`a命令和i命令`**

append insert
	
	1i 第一行前插入一行
	1a $a 第一行 最后一行插入
		sed "1 i This is addition" file.txt
		sed "$ a This is addition" file.txt
	匹配到fish后增加
		sed "/fish/a This add" file.txt
	每一行增加:
		sed "/my/a ----" file.txt
	
**`c命令`**

替换匹配行

	sed "2 c This is my monkey, my monkey's name is wukong" my.txt
	sed "/fish/c This is my monkey, my monkey's name is wukong" my.txt
	
**`d命令`**

删除匹配行
	
	sed '/fish/d' my.txt
	sed '2d' my.txt
	sed '2,$d' my.txt
	
**`p命令`**
	
	匹配fish并输出，可以看到fish的那一行被打了两遍，这是因为sed处理时会把处理的信息输出
	$ sed '/fish/p' my.txt
		This is my cat, my cat's name is betty
		This is my dog, my dog's name is frank
		This is my fish, my fish's name is george
		This is my fish, my fish's name is george
		This is my goat, my goat's name is adam
 
	使用n参数就好了
	$ sed -n '/fish/p' my.txt
		This is my fish, my fish's name is george
 
	从一个模式到另一个模式
	$ sed -n '/dog/,/fish/p' my.txt
		This is my dog, my dog's name is frank
		This is my fish, my fish's name is george
 
	从第一行打印到匹配fish成功的那一行
	$ sed -n '1,/fish/p' my.txt
		This is my cat, my cat's name is betty
		This is my dog, my dog's name is frank
		This is my fish, my fish's name is george

`-n 参数`
	
pattern space的概念
 正常即使没有匹配到的行也会显示 即显示两遍


----
##几个知识点


`关于address可以使用相对位置`，如：
	
	其中的+3表示后面连续3行
	sed '/dog/,+3s/^/# /g' pets.txt
		This is my cat
  			my cat's name is betty
		# This is my dog
		#   my dog's name is frank
		# This is my fish
		#   my fish's name is george
		This is my goat
  			my goat's name is adam

`命令打包`
	
	# 对3行到第6行，执行命令/This/d
	$ sed '3,6 {/This/d}' pets.txt
	This is my cat
	  my cat's name is betty
	  my dog's name is frank
	  my fish's name is george
	This is my goat
	  my goat's name is adam
 
	# 对3行到第6行，匹配/This/成功后，再匹配/fish/，成功后执行d命令
	$ sed '3,6 {/This/{/fish/d}}' pets.txt
	This is my cat
	  my cat's name is betty
	This is my dog
	  my dog's name is frank
	  my fish's name is george
	This is my goat
	  my goat's name is adam
 
	# 从第一行到最后一行，如果匹配到This，则删除之；如果前面有空格，则去除空格
	$ sed '1,${/This/d;s/^ *//g}' pets.txt
	my cat's name is betty
	my dog's name is frank
	my fish's name is george
	my goat's name is adam

`Hold Space`

 这部分好麻烦 参考这里吧 最下面
 http://coolshell.cn/articles/9104.html#comment-592073

	g：将hold space中的内容拷贝到pattern space中，原来pattern space里的内容清除
	G：将hold space中的内容append到pattern space\n后
	h：将pattern space中的内容拷贝到hold space中，原来的hold space里的内容被清除
	H：将pattern space中的内容append到hold space\n后
	x：交换pattern space和hold space的内容

	sed -e ‘/test/h’ -e ‘$G‘  example：在这个例子里，匹配test的行被找到后，将存入模式空间，h命令将其复制并存入一个称为保持缓存区的特殊缓冲区内。第二条语句的意思是，当到达最后一行后，G命令取出保持缓冲区的行，然后把它放回模式空间中，且追加到现在已经存在于模式空间中的行的末尾。在这个例子中就是追加到最后一行。简单来说，任何包含test的行都被复制并追加到该文件的末尾。

	sed -e ‘/test/h’ -e ‘/check/x’ example：互换模式空间和保持缓冲区的内容。也就是把包含test与check的行互换。

`执行sed脚本：`
sed -f test.sed

	Sed对于脚本中输入的命令非常挑剔，在命令的末尾不能有任何空白或文本，如果在一行中有多个命令，要用分号分隔。以#开头的行为注释行，且不能跨行。

ps: 去除空白行：sed ‘/^ *$/d’ file