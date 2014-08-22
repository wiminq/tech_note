#基于SSD的数据库性能优化


[原文](http://www.hellodb.net/2010/10/ssd-database-2.html)


@hellodba

----


##数据库IO特点分析

数据库基于磁盘设计:
	
	sequential logging
	In-place update

日志文件顺序写:
	
	同步写入,响应延迟低
	连续位置的随机写IO
	
数据文件随机写:

	异步写入
	大量的随机写IO

瓶颈分析:

	IPOS:
		小IO 数据文件随机读,随机写,日志文件写
	吞吐量:
		大IO 数据文件连续读
		
`SSD数据库优化实践`

	日志文件在磁盘上(这个?我感觉...)
	控制数据库刷盘频率
	增加spare area 改善写性能
	IO调度算法:deadline NOOP
	减小page size:16K->8K
	关闭MySQL预读
	文件系统:xfs...ext3

----

	
`数据库IO特点分析`

IO有四种类型：连续读，随机读，随机写和连续写，连续读写的IO size通常比较大（128KB-1MB），主要衡量吞吐量，而随机读写的IO size比较小(小于8KB)，主要衡量IOPS和响应时间。数据库中的全表扫描是连续读IO，索引访问则是典型的随机读IO，日志文件是连续写IO，而数据文件则是随机写IO。

数据库系统基于传统磁盘访问特性来设计，最大特点是日志文件采用sequential logging，数据库中的日志文件，要求必须在事务提交时写入到磁盘，对响应时间的要求很高，所以设计为顺序写入的方式，可以有效降低磁盘寻道花费的时间，减少延迟时间。日志文件的顺序写入，虽然是物理位置是连续的，但是并不同于传统的连续写类型，日志文件的IO size很小（通常小于4K）,每个IO之间是独立的（磁头必须抬起来重新寻道，并等待磁盘转动到相应的位置），而且间隔很短，数据库通过log buffer（缓存）和group commit的方式（批量提交）来达到提高IO size的大小，并减少IO的次数，从而得到更小的响应延迟，所以日志文件的顺序写入可以被认为是“连续位置的随机写入”，瓶颈还是在IOPS，而不是吞吐量。

数据文件采用in place update的方式，意思是数据文件的修改都是写入到原来的位置，数据文件不同于日志文件，并不会在事务commit时写入数据文件，只有当数据库发现dirty buffer过多或者需要做checkpoint动作时，才会刷新这些dirty buffer到相应的位置，这是一个异步的过程，通常情况下，数据文件的随机写入对IO的要求并不是特别高，只要满足checkpoint和dirty buffer的要求就可以了。

`SSD的IO特点分析`

1.随机读能力非常好，连续读性能一般，但比普通SAS磁盘好。

2.不存在磁盘寻道的延迟时间，随机写和连续写的响应延迟差异不大。

3.erase-before-write特性，造成写入放大，影响写入的性能。

4.写磨损特性，采用wear leveling算法延长寿命，但同时会影响读的性能。

5.读和写的IO响应延迟不对等（读要大大好于写），而普通磁盘读和写的IO响应延迟差异很小。

6.连续写比随机写性能好，比如1M顺序写比128个8K的随即写要好很多，因为随机写会带来大量的擦除。

`基于SSD的上述特性，如果将数据库全部放在SSD上，可能会有以下的问题：`

1.日志文件sequential logging会反复擦写同一位置，虽然有损耗均衡算法，但是长时间写入依然会导致性能下降。

2.数据文件in place update会产生大量的随机写入，erase-before-write会产生写入放大。

3.数据库读写混合型应用，存在大量的随机写入，同时会影响读的性能，产生大量的IO延迟。

`基于SSD的数据库优化法则：`

基于SSD的优化就是解决erase-before-write产生的写入放大的问题，不同类型的IO分离，减少写操作带来的性能影响。

1.将sequential logging修改为In-page logging，避免对相同位置的反复擦写。

2.通过缓存写入的方式将大量的in-place update随机写入合并为少量顺序写入。

3.利用SSD随机读写能力高的特点，减少写增加读，从而达到整体性能的提升。

`In-page logging`

In-page logging是基于SSD对数据库sequential logging的一种优化方法，数据库中的sequential logging对传统磁盘是非常有利的，可以大大提高响应时间，但是对于SSD就是噩梦，因为需要对同一位置反复擦写，而wear leveling算法虽然可以平衡负载，但是依然会影响性能，并产生大量的IO延迟。所以In-page logging将日志和数据合并，将日志顺序写入改为随机写入，基于SSD对随机写和连续写IO响应延迟差异不大的特性，避免对同一位置反复擦写，提高整体性能。

In-page logging基本原理：在data buffer中，有一个in-memory log sector的结构，类似于log buffer，每个log sector是与data block对应的。在data buffer中，data和log并不合并，只是在data block和log sector之间建立了对应关系，可以将某个data block的log分离出来。但是，在SSD底层的flash memory中，数据和日志是存放在同一个block（擦除单元），每个block都包含data page和log page。

当日志信息需要写入的时候（log buffer空间不足或者事务提交），日志信息会写入到flash memory对应的block中，也就是说日志信息是分布在很多不同的block中的，而每个block内的日志信息是append write，所以不需要擦除的动作。当某个block中的log sector写满的时候，这时会发生一个动作，将整个block中的信息读出，然后应用block中的log sector，就可以得到最新的数据，然后整个block写入，这时，block中的log sector是空白的。

在in-page logging方法中，data buffer中的dirty block是不需要写入到flash memory中的，就算dirty buffer需要被交换出去，也不需要将它们写入flash memory中。当需要读取最新的数据，只要将block中的数据和日志信息合并，就可以得到最新的数据。

In-page logging方法，将日志和数据放在同一个擦除单元内，减少了对flash相同位置的反复擦写，而且不需要将dirty block写入到flash中，大量减少了in-place update的随机写入和擦除的动作。虽然在读取时，需要做一个merge的操作，但是因为数据和日志存放在一起，而且SSD的随机读取能力很高，in-page logging可以提高整体的性能。



`SSD作为写cache—append write`

SSD可以作为磁盘的写cache，因为SSD连续写比随机写性能好，比如：1M顺序写比128个8K的随机写要好很多，我们可以将大量随机写合并成为少量顺序写，增加IO的大小，减少IO(擦除)的次数，提高写入性能。这个方法与很多NoSQL产品的append write类似，即不改写数据，只追加数据，需要时做合并处理。

基本原理：当dirty block需要写入到数据文件时，并不直接更新原来的数据文件，而是首先进行IO合并，将很多个8K的dirty block合并为一个512KB的写入单元，并采用append write的方式写入到一个cache file中（保存在SSD上），避免了擦除的动作，提高了写入性能。cache file中的数据采用循环的方式顺序写入，当cache file空间不足够时，后台进程会将cache file中的数据写入到真正的数据文件中（保存在磁盘上），这时进行第二次IO合并，将cache file内的数据进行合并，整合成为少量的顺序写入，对于磁盘来说，最终的IO是1M的顺序写入，顺序写入只会影响吞吐量，而磁盘的吞吐量不会成为瓶颈，将IOPS的瓶颈转化为吞吐量的瓶颈，从而提升了整体系统能力。

读取数据时，必须首先读取cache file，而cache file中的数据是无序存放的，为了快速检索cache file中的数据，一般会在内存中为cache file建立一个索引，读取数据时会先查询这个索引，如果命中查询cache file，如果没有命中，再读取data file（普通磁盘），所以，这种方法实际不仅仅是写cache，同时也起到了读cache的作用。

SSD并不适合放数据库的日志文件，虽然日志文件也是append write，但是因为日志文件的IO size比较小，而且必须同步写入，无法做合并处理，对SSD来说，需要大量的擦除动作。我们也曾经尝试把redo log放在SSD上，考虑到SSD的随机写入也可以达到3000 IOPS，而且响应延时比磁盘低很多，但是这依赖于SSD本身的wear leveling算法是否优秀，而且日志文件必须是独立存放的，如果日志文件的写入是瓶颈，也算是一种解决方案吧。通常情况下，我还是建议日志文件放在普通磁盘上，而不是SSD。

`SSD作为读cache—flashcache`

因为大部分数据库都是读多写少的类型，所以SSD作为数据库flashcache是优化方案中最简单的一种，它可以充分利用SSD读性能的优势，又避免了SSD写入的性能问题。实现的方法有很多种，可以在读取数据时，将数据同时写入SSD，也可以在数据被刷出buffer时，写入到SSD。读取数据时，首先在buffer中查询，然后在flashcache中查询，最后读取datafile。

SSD作为flashcache与memcache作为数据库外部cache的最大区别在于，SSD掉电后数据是不丢失的，这也引起了另外一个思考，当数据库发生故障重启后，flashcache中的数据是有效还是无效？如果是有效的，那么就必须时刻保证flashcache中数据的一致性，如果是无效的，那么flashcache同样面临一个预热的问题（这与memcache掉电后的问题一样）。目前，据我所知，基本上都认为是无效的，因为要保持flashcache中数据的一致性，非常困难。

flashcache作为内存和磁盘之间的二级cache，除了性能的提升以外，从成本的角度看，SSD的价格介于memory和disk之间，作为两者之间的一层cache，可以在性能和价格之间找到平衡。

总结

随着SSD价格不断降低，容量和性能不断提升，SSD取代磁盘只是个时间问题。

Tape is Dead，Disk is Tape，Flash is Disk，RAM Locality is King.        Jim Gray




-------

最终不是还是所有的数据都放在了SSD上么....



测试数据:

[Fusionio性能测试与瓶颈分析](http://www.hellodb.net/2011/06/fusionio-performance.html)


结论:
	
	Fusionio与磁盘相比，随机IO可以轻松到达5w+，响应时间小于1ms，而吞吐量瓶颈则大致在600MB-700MB之间，官方数据与实测数据差异不大。通过上述数据分析可以看到，fusionio的IOPS很高，通常不会成为瓶颈，而吞吐量可能会在IOPS之前成为瓶颈。我们可以计算一下，600MB吞吐量，IO大小为128K，IOPS只有4800；8K的随机读，IOPS达到5W时，吞吐量已经接近400MB。虽然单块fusionio卡的吞吐量比磁盘大，但是考虑到价格因素，fusionio并不适合追求吞吐量的系统