require "admiral"
require "compress/gzip"

class GrepFile < Admiral::Command
  define_argument target,
    description: "target file, support flat or .gz file or stdin(-)",
    required: true
  define_argument query,
    description: "query file,  support flat or .gz file or stdin(-)",
    required: true
  define_flag column_target : String,
    default: "1",
    description: "choose which column to compare for target file, allow multil columns as keyword (example 1,3,5)"
  define_flag column_query : String,
    default: "1",
    description: "choose which column to compare for query file, allow multil columns as keyword (example 1,3,5)"
  define_flag print_header : Int32,
    default: 0,
    description: "1 mean output header, 0 mean not output header"
  define_flag column_name_target : String,
    default: "",
    description: "use with --header-target, and not allow with --column_target  together! choose which column to compare for target file, allow multil columns as keyword (example key1,key2,key3)"
  define_flag column_name_query : String,
    default: "",
    description: "use with --header-query, and not allow with --column_query  together! choose which column to compare for target file, allow multil columns as keyword (example key1,key2,key3)"
  define_flag header_query : Int32,
    default: 1,
    description: "set which one line is the header of query file. only work with  --column-name-query"
  define_flag header_target : Int32,
    default: 1,
    description: "set which one line is the header of target file.  only work with --print-header or --column-name-target"

  define_flag sort_output_by_query : Int32,
    default: 0_i32,
    description: "sort ouput by query column order"
  define_flag ignore_line_mathed_by : String,
    default: "^[#@]",
    description: "if content of column start with # or @, will skip this line, support regex syntax"
  define_flag ignore_case : Int32,
    default: 0_i32,
    description: "if set to 1 mean will ignore case for query and target match, default 0"
  define_flag delete_chars_from_column : String,
    default: "^>",
    description: "delete > from content of column, support regex syntax"
  define_flag invert_match : Int32,
    default: 0_i32,
    description: "if >=1, mean invert the sense of matching, to select non-matching lines"
  define_flag reverse_complement : Int32,
    default: 0_i32,
    description: "if >=1, mean reverse_complement the query"
  define_flag sep_query : String,
    default: "\t",
    description: "query separator, '\\t' or '\\s' or other string"
  define_flag exact_match : Int32,
    default: 1_i32,
    description: "1 -> mean equal totally; 2 -> mean query fully is in target; 3 -> mean target fully is in query"
  define_flag sep_target : String,
    default: "\t",
    description: "target separator, '\\t' or '\\s' or other string"

  define_help description: "A replace for $ grep -f (which cost too many memory and time) in Linux"
  define_version "1.0.5"

  COMPILE_TIME = Time.local

  def run
    if ARGV.size == 0 || ARGV.size == 1
      # puts "complie time: #{COMPILE_TIME}"
      # app = __FILE__.gsub(/\.cr$/, "")
      # puts `#{app} --help`
      # exit 1
      puts "Contact: https://github.com/orangeSi/grepfile/issues"
      GrepFile.run "--help"
    end

    query_ids = {} of String => String
    ignore_line_mathed_by = flags.ignore_line_mathed_by
    target = ARGV[0]
    query = ARGV[1]
    if (target == "stdin" || target == "-") && ( query == "stdin" || query == "-")
      raise "error: target and query should not both be stdin, only one or zero is stdin!"
    end

    # check --column_name_target and --column_target is not both used!
    column_target = flags.column_target.strip(",")
    column_query = flags.column_query.strip(",")
    if flags.column_name_target != "" && flags.column_target != ""
      column_target = ""
      #raise "error: only choose one parameter from --column-name-target or --column-target !"
    end
    if flags.column_name_query != "" && flags.column_query != ""
      column_query = ""
      #raise "error: only choose one parameter from --column-name-query or --column-query !"
    end




    # read query file
    # puts "arguments.query is #{arguments.query}"
    line_index = 0
    if query == "stdin" || query == "-"
      STDIN.each_line do |line|
        line_index += 1
        # get column number by column name
        if flags.column_name_query != "" && line_index == flags.header_query
	  column_query = get_column_number_by_name(line: line, colname: flags.column_name_query, sep: flags.sep_query)
          next
        end

        query_ids = read_query_file(line, column_query, query_ids, ignore_line_mathed_by: ignore_line_mathed_by, sep_query: flags.sep_query, query: "stdin", delete_chars_from_column: flags.delete_chars_from_column, ignore_case: flags.ignore_case, reverse_complement: flags.reverse_complement)
      end
    elsif query.match(/.*\.gz$/) # gzip file
      Compress::Gzip::Reader.open(query) do |gfile|
        gfile.each_line do |line|
          line_index += 1
          # get column number by column name
          if flags.column_name_query != "" && line_index == flags.header_query
	    column_query = get_column_number_by_name(line: line, colname: flags.column_name_query, sep: flags.sep_query)
            next
          end

          query_ids = read_query_file(line, column_query, query_ids, ignore_line_mathed_by: ignore_line_mathed_by, sep_query: flags.sep_query, query: query, delete_chars_from_column: flags.delete_chars_from_column, ignore_case: flags.ignore_case, reverse_complement: flags.reverse_complement)
        end
      end
    else # not gzip file
      File.each_line(query) do |line|
        line_index += 1
        # get column number by column name
        if flags.column_name_query != "" && line_index == flags.header_query
	    column_query = get_column_number_by_name(line: line, colname: flags.column_name_query, sep: flags.sep_query)
            next
        end

        query_ids = read_query_file(line, column_query, query_ids, ignore_line_mathed_by: ignore_line_mathed_by, sep_query: flags.sep_query, query: query, delete_chars_from_column: flags.delete_chars_from_column, ignore_case: flags.ignore_case, reverse_complement: flags.reverse_complement)
      end
    end

    # # read target file
    target_ids = {} of String => String
    target_ids_num = 0
    sort_output_by_query_flag = (flags.sort_output_by_query >= 1)
    sorted_output = {} of (Bool|String) => String 
    line_index = 0
    if target == "stdin" || target == "-"
      STDIN.each_line do |line|
        line_index += 1
        # get column number by column name
        if flags.print_header >= 1 && flags.header_target == line_index
           puts line
        end
    
        if flags.column_name_target != "" && line_index == flags.header_target
	    column_target = get_column_number_by_name(line: line, colname: flags.column_name_target, sep: flags.sep_target)
            next
        end

        output_flag = read_target_file(line, query_ids, ignore_line_mathed_by: ignore_line_mathed_by, sep_target: flags.sep_target, target: "target", column_target: column_target, delete_chars_from_column: flags.delete_chars_from_column, invert_match: flags.invert_match, exact_match: flags.exact_match, ignore_case: flags.ignore_case, sort_output_by_query_flag: sort_output_by_query_flag)
        if output_flag != ""
	  sorted_output[output_flag] = line
	end
      end
    elsif target.match(/.*\.gz$/) # gzip file
      Compress::Gzip::Reader.open(target) do |gfile|
        gfile.each_line do |line|
          line_index += 1
          # get column number by column name
          if flags.print_header >= 1 && flags.header_target == line_index
             puts line
          end
          if flags.column_name_target != "" && line_index == flags.header_target
 	    column_target = get_column_number_by_name(line: line, colname: flags.column_name_target, sep: flags.sep_target)
            next
          end

          output_flag = read_target_file(line, query_ids, ignore_line_mathed_by: ignore_line_mathed_by, sep_target: flags.sep_target, target: target, column_target: column_target, delete_chars_from_column: flags.delete_chars_from_column, invert_match: flags.invert_match, exact_match: flags.exact_match, ignore_case: flags.ignore_case, sort_output_by_query_flag: sort_output_by_query_flag)
          if output_flag != ""
	    sorted_output[output_flag] = line
  	  end
        end
      end
    else # not gzip file
      File.each_line(target) do |line|
        line_index += 1
        # get column number by column name
        if flags.print_header >= 1 && flags.header_target == line_index
           puts line
        end
        if flags.column_name_target != "" && line_index == flags.header_target
	    column_target = get_column_number_by_name(line: line, colname: flags.column_name_target, sep: flags.sep_target)
            next
        end

        output_flag = read_target_file(line, query_ids, ignore_line_mathed_by: ignore_line_mathed_by, sep_target: flags.sep_target, target: target, column_target: column_target, delete_chars_from_column: flags.delete_chars_from_column, invert_match: flags.invert_match, exact_match: flags.exact_match, ignore_case: flags.ignore_case, sort_output_by_query_flag: sort_output_by_query_flag)
        if output_flag != ""
	  sorted_output[output_flag] = line
  	end
      end
    end

    if sort_output_by_query_flag
    	query_ids.each_key do |k|
           puts sorted_output[k] if sorted_output.has_key?(k)
        end
    end

  end
def reverse_complement(dna : String) : String
    complement = dna.chars.map do |nucleotide|
    case nucleotide
    when 'A' then 'T'
    when 'T' then 'A'
    when 'C' then 'G'
    when 'G' then 'C'
    when 'a' then 't'
    when 't' then 'a'
    when 'c' then 'g'
    when 'g' then 'c'
    else nucleotide
    end
   end
   return complement.reverse.join
end

def get_column_number_by_name(line : String, colname : String, sep : String)
    # get column number by column name
    column = ""
    arr = line.split(/#{sep}/)
    colname.strip(",").split(/,/).each do |e1|
      arr.each_with_index do |e2, i2|
        if e1 == e2
          column = "#{column},#{i2+1}"
          #puts "gets column=#{column}"
          break
        end
     end
   end
   column = column.strip(",")
   if column.split(/,/).size != colname.strip(",").split(/,/).size
     raise "error: column name #{colname} are not in  line:#{line}\n"
   end
   #puts "column=#{column}"
   return column
end

  def read_target_file(line : String, query_ids : Hash(String, String), ignore_line_mathed_by : String = "^#", sep_target : String = "\t", target : String = "target", column_target : String = "1", delete_chars_from_column : String = "^>", invert_match : Int32 = 0, exact_match : Int32 = 1, ignore_case : Int32 = 0, sort_output_by_query_flag : Bool = false)
    return false if ignore_line_mathed_by != "" && line.match(/#{ignore_line_mathed_by}/)
    return false if line.match(/^\s*$/)
    arr = line.split(/#{sep_target}/)
    id = ""
    #puts "column_target=#{column_target}"
    column_target.split(",").each do |tcol|
       tcol = tcol.to_i
       raise "error: #{target} only have #{arr.size} column in line #{line}, but tcol=#{tcol} in --column_target #{column_target}, try to change --sep_target for line: #{arr}\n" if tcol > arr.size
       tcol_id = arr[tcol - 1]
       tcol_id = tcol_id.gsub(/#{delete_chars_from_column}/, "") if delete_chars_from_column != ""
       if id != ""
          id = "#{id}_#{tcol_id}"
       else
          id = tcol_id
       end
    end
    
    output_flag = ""
    id = id.upcase if ignore_case > 0
    #puts "target id = #{id}"
    #for exact_match: 1 -> mean equal totally; 2 -> mean query 全部被包含在target中; 3 -> 和2相反即target被包含在query中
    if invert_match == 0
      if exact_match == 1
        if query_ids.has_key?(id)
          if sort_output_by_query_flag
            output_flag = id
          else
            puts "#{line}"
          end
        end
      elsif exact_match == 2
        query_ids.each_key do |k|
          if id =~ /#{k}/
            if sort_output_by_query_flag
              output_flag = k
            else
              puts "#{line}"
            end
            break
          end
        end
      elsif exact_match == 3
        query_ids.each_key do |k|
          if k =~ /#{id}/
            if sort_output_by_query_flag
              output_flag = k
            else
              puts "#{line}"
            end
            break
          end
        end  
      else
         raise "error: exact_match=#{exact_match}, but only support 1/2/3"
      end
    else # flags.invert_match >=1
      if sort_output_by_query_flag
         raise "error: --invert_match #{invert_match} not support --sort_output_by_query_flag #{sort_output_by_query_flag}"
      end
      if exact_match == 1
        if !query_ids.has_key?(id)
          puts "#{line}"
        end
      elsif exact_match == 2
        matched_flag = 0
        query_ids.each_key do |k|
          if id =~ /#{k}/
            matched_flag = 1
            break
          end
        end
        if matched_flag == 0
          puts "#{line}"
        end
      elsif exact_match == 3
        matched_flag = 0
        query_ids.each_key do |k|
          if k =~ /#{id}/
            matched_flag = 1
            break
          end
        end
        if matched_flag == 0
          puts "#{line}"
        end
      else
         raise "error: exact_match=#{exact_match}, but only support 1/2/3"
      end
    end
    return output_flag
  end

  def read_query_file(line : String, column_query : String, query_ids : Hash(String, String), ignore_line_mathed_by : String = "", sep_query : String = "\t", query : String = "", delete_chars_from_column : String = "", ignore_case : Int32 = 0, reverse_complement : Int32 = 0)
    return query_ids if ignore_line_mathed_by != "" && line.match(/#{ignore_line_mathed_by}/)
    return query_ids if line.match(/^\s*$/)
    arr = line.split(/#{sep_query}/)
    #puts "column_query=#{column_query}"

    id = ""
    column_query.split(",").each do |tcol|
       tcol = tcol.to_i
       raise "error: query #{query} only have #{arr.size} columns, but --column_query #{column_query}, try to change --sep_query for line: #{arr}\n" if tcol > arr.size
       tcol_id = arr[tcol - 1]
       tcol_id = tcol_id.gsub(/#{delete_chars_from_column}/, "") if delete_chars_from_column != ""
       if id != ""
          id = "#{id}_#{tcol_id}"
       else
          id = tcol_id
       end
    end

    id = id.upcase if ignore_case > 0
    id = reverse_complement(id) if reverse_complement >0
    #puts "query id = #{id}"
    unless query_ids.has_key?(id)
      query_ids[id] = ""
    end
    return query_ids
  end
end

GrepFile.run
