#!/opt/ruby_2.5.1/bin/ruby -w
# coding: utf-8

require 'set'
require "curses"
require_relative "process_bar"





module M_通用函数
  
  def exit_msg(消息=nil,退出码=10)
    puts "#{消息},#{退出码}"
    exit 退出码
  end
end

class C_圆盘
  include M_通用函数
  attr_accessor :大小
  def initialize(大小=nil)
    大小 || exit_msg("圆盘没有大小参数",1)
    @大小=大小
  end
end

class C_圆柱
  include M_通用函数
  attr_accessor :名称,:层级,:状态
  def initialize(名称="没有名称",层级=4)
    @名称=名称
    @层级=层级
    @状态={}
    @层级.times {|x|
      x += 1
      @状态.merge!({"第#{sprintf("%2d", x)}层" => nil}) 
    }
    #
    # 做排序处理，按key，升序
    #
    @状态=@状态.sort_by {|k,v| k}.to_h
  end

  def 遍历层态
  	puts "#{名称}----------------"
    逆序状态.each_pair {|层数,层态|
      puts %Q{#{层数} #{if 层态==nil; '空' else 层态.to_s + " -> " + 层态.大小.to_s end }}
    }
  end

  def 添加圆盘(圆盘=nil)
    圆盘 || exit_msg("没有给定圆盘对象",5)
    @状态.each_pair {|层数,层态|
      
      if 层态 == nil 
        @状态[层数]=圆盘
        return "添加成功" 
      else
        if 层态.大小 > 圆盘.大小
          next
        elsif 层态.大小 < 圆盘.大小
          exit_msg("发现圆盘过大无法添加",78)
        end
      end
    }
  end

  def 删除圆盘(圆盘=nil)
    exit_msg("参数类型不对",52) if 圆盘.class != C_圆盘
    exit_msg("没有给定圆盘对象",51) if 圆盘==nil
    圆盘所在层数=根据大小找圆盘位置 圆盘.大小
    exit_msg("上层有圆盘，不能移动",53) if @状态[上一层(圆盘所在层数)] != nil
    @状态[圆盘所在层数]=nil

  end

  def 当前层圆盘(层数)
      #
      # 如果找不到，会返回nil
      #
      @状态["#{层数}"]
  end

  def 上一层(层=nil)
    exit_msg "层应该是字符串信息",53 if 层.class != String
    层数字= /\d+/.match(层)[0].to_i
    层数字 += 1
    return "第#{sprintf "%2d",层数字}层"
  end

  def 下一层(层=nil)
    exit_msg "层应该是字符串信息",53 if 层.class != String
    层数字= /\d+/.match(层)[0].to_i
    层数字 -= 1
    return "第#{sprintf "%2d",层数字}层"
  end

  def 逆序状态
    @状态.sort {|a,b| a <=>b }.reverse.to_h
  end
  
  def 根据大小找圆盘位置(大小=nil)
    exit_msg "没有指定圆盘大小",7 if 大小==nil
    #p @状态
    @状态.each_pair {|层数,层态|
      return 层数 if 层态.大小 == 大小
    }
  end
  alias :圆盘层 :根据大小找圆盘位置

  def 根据大小找圆盘(大小=nil)
  	exit_msg "没有指定圆盘大小",71 if 大小==nil
    @状态.each_pair {|层数,层态|
      return 层态 if 层态.大小 == 大小
    } 
  end
end



if ARGV[0] != nil
  if ARGV[0].include? 'help'
    puts "#{__FILE__} 层数 延迟 图标"
    exit
  end 
  层次总数 = ARGV[0].to_i

end
 

(层次总数 = ARGV[0].to_i) if ARGV[0] != nil

($操作延迟 = ARGV[1].to_f) if ARGV[1] != nil
$操作延迟 ||= 0.5

$图标 ||= nil
($图标 = ARGV[2]) if ARGV[2] != nil





层次总数 ||= 8
最大盘大小=层次总数 


$进度条=C_进度条.new(2**层次总数-1,"进度",100)




第一个圆柱=C_圆柱.new "第一个圆柱",层次总数
第二个圆柱=C_圆柱.new "第二个圆柱",层次总数
第三个圆柱=C_圆柱.new "第三个圆柱",层次总数

层次总数.times {|x|
	x=层次总数-x
	第一个圆柱.添加圆盘 C_圆盘.new x
}

圆柱集合=Set.new ; 圆柱集合.add 第一个圆柱 ; 圆柱集合.add 第二个圆柱 ; 圆柱集合.add 第三个圆柱

#
# 这个模块中定义的函数，需要判断类，所以必须放在类下面
#

class C_河内塔
  include M_通用函数
  
  attr_accessor :圆柱集合

  def initialize(圆柱集合=nil)
    圆柱集合 || exit_msg("河内塔中没有任何圆柱",2)
    @圆柱集合=圆柱集合
  end

	def 屏幕输出(延迟=0.5,图标=nil)
		Curses.init_screen
		Curses.curs_set(0)  # 0 表示隐藏光标
    Curses.addstr $进度条.更新
		行坐标=5
		列坐标=-40
		@圆柱集合.each {|圆柱|

			列坐标 += 40
			行坐标 = 5
			圆柱.逆序状态.each_pair {|k,v|
				行坐标 += 1
				Curses.setpos(行坐标,列坐标)

				if $图标 != nil
					if v.class==C_圆盘
						tmp=''
						v.大小.times {
							tmp << $图标 
						}
					end
					Curses.addstr("#{k} #{tmp}") 					
				else
					Curses.addstr("#{k} #{v} #{v.大小 if v.class==C_圆盘}")
				end

				Curses.refresh
			}

		}
		
		sleep 延迟
		Curses.close_screen			
	end



  def 返回第三个圆柱(源圆柱,目的圆柱)
    exit_msg("参数不是圆柱实例，请检查给定的参数",3) if 源圆柱.class != C_圆柱 or 目的圆柱.class != C_圆柱 
    另外一个圆柱的集合= @圆柱集合 - Set[源圆柱,目的圆柱]
    exit_msg("另外一个圆柱返回了多个，请检查程序",4) if 另外一个圆柱的集合.size != 1
    
    #
    # if判断之后，return 最终的对象
    #

    if 另外一个圆柱的集合.to_a[0].class == C_圆柱
      另外一个圆柱的集合.to_a[0]
    else
      exit_msg("返回的对象不是圆柱",4)
    end
  end

  def 按名称返回圆柱(圆柱名称=nil)
    @圆柱集合.each {|x|
      #
      # 符合判断，直接return 结束方法执行，强制跳出块儿的执行
      #
      return x if x.名称==圆柱名称
    }
  end

  def 移动一层(圆盘=nil,源圆柱=nil,目的圆柱=nil)
  	if 圆盘.class !=  C_圆盘
  		exit_msg "圆盘的类型不对 #{圆盘.class}",65
  	end
  	if 源圆柱.class !=  C_圆柱
  		exit_msg "源圆柱的类型不对",65
  	end
  	if 目的圆柱.class !=  C_圆柱
  		exit_msg "目的圆柱的类型不对",65
  	end
	源圆柱.删除圆盘   圆盘
	目的圆柱.添加圆盘 圆盘
  end

  def 移动二层(较低层圆盘=nil,源圆柱=nil,目的圆柱=nil)
  	#p 较低层圆盘

  	if 较低层圆盘.class !=  C_圆盘
  		exit_msg "圆盘的类型不对",66
  	end
  	if 源圆柱.class !=  C_圆柱
  		exit_msg "源圆柱的类型不对",66
  	end
  	if 目的圆柱.class !=  C_圆柱
  		exit_msg "目的圆柱的类型不对",66
  	end
  	另外一个圆柱= 返回第三个圆柱 源圆柱,目的圆柱
  	较低层=源圆柱.根据大小找圆盘位置(较低层圆盘.大小)
  	高层=源圆柱.上一层(较低层)
  	高层之上=源圆柱.上一层(高层)
  	上一层圆盘=源圆柱.状态[高层]

  	if 源圆柱.状态[高层] == nil
  		 移动一层 较低层圆盘 , 源圆柱 , 目的圆柱 ; 
  		 return "完成"
  	end 

  	if 源圆柱.状态[高层之上] == nil
	  	移动一层 上一层圆盘 , 源圆柱 , 另外一个圆柱 ; 屏幕输出 $操作延迟,$图标
	  	移动一层 较低层圆盘 , 源圆柱 , 目的圆柱     ; 屏幕输出 $操作延迟,$图标
	  	移动一层 上一层圆盘 , 另外一个圆柱 , 目的圆柱  ; 屏幕输出 $操作延迟,$图标
	else
		移动二层 源圆柱.状态[高层] , 源圆柱 , 另外一个圆柱
		移动一层 较低层圆盘 , 源圆柱 , 目的圆柱 ; 屏幕输出 $操作延迟,$图标
		移动二层 上一层圆盘 , 另外一个圆柱 , 目的圆柱
  	end
  end

  def 展示整个塔
  	sleep 0.01
  	按名称返回圆柱("第一个圆柱").遍历层态
  	按名称返回圆柱("第二个圆柱").遍历层态
  	按名称返回圆柱("第三个圆柱").遍历层态
  end
end

河内塔=C_河内塔.new 圆柱集合

#河内塔.展示整个塔
puts "开始"
河内塔.移动二层 河内塔.按名称返回圆柱("第一个圆柱").根据大小找圆盘(最大盘大小) , 河内塔.按名称返回圆柱("第一个圆柱") , 河内塔.按名称返回圆柱("第三个圆柱")


河内塔.屏幕输出 3600
