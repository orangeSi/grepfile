require "admiral"
require "compress/gzip"

class GrepFile < Admiral::Command
  define_argument target,
    description: "target file, support flat or .gz file or stdin(by -)",
    required: true
  define_argument query,
    description: "query file,  support flat or .gz file or stdin(by -)",
    required: true
  define_flag column_target : Int32,
    default: 1_i32,
    description: "choose which column to compare"
  define_flag column_query : Int32,
    default: 1_i32,
    description: "choose which column to compare"
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
  define_flag sep_query : String,
    default: "\t",
    description: "query separator, '\\t' or '\\s' or other string"
  define_flag exact_match : Int32,
    default: 1_i32,
    description: "if >=1, mean equal totally else mean macth"
  define_flag sep_target : String,
    default: "\t",
    description: "target separator, '\\t' or '\\s' or other string"

  define_help description: "A replace for $ grep -f (which cost too many memory and time) in Linux"
  define_version "1.0.4"

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

    # read query file
    # puts "arguments.query is #{arguments.query}"
    if ARGV[1] == "-"
      STDIN.each_line do |line|
        query_ids = read_query_file(line, flags.column_query, query_ids, ignore_line_mathed_by: ignore_line_mathed_by, sep_query: flags.sep_query, query: "stdin", delete_chars_from_column: flags.delete_chars_from_column, ignore_case: flags.ignore_case)
      end
    elsif query.match(/.*\.gz$/) # gzip file
      Compress::Gzip::Reader.open(query) do |gfile|
        gfile.each_line do |line|
          query_ids = read_query_file(line, flags.column_query, query_ids, ignore_line_mathed_by: ignore_line_mathed_by, sep_query: flags.sep_query, query: query, delete_chars_from_column: flags.delete_chars_from_column, ignore_case: flags.ignore_case)
        end
      end
    else # not gzip file
      File.each_line(query) do |line|
        query_ids = read_query_file(line, flags.column_query, query_ids, ignore_line_mathed_by: ignore_line_mathed_by, sep_query: flags.sep_query, query: query, delete_chars_from_column: flags.delete_chars_from_column, ignore_case: flags.ignore_case)
      end
    end

    # # read target file
    target_ids = {} of String => String
    target_ids_num = 0
    sort_output_by_query_flag = (flags.sort_output_by_query >= 1)
    sorted_output = {} of (Bool|String) => String 
    if ARGV[0] == "-"
      STDIN.each_line do |line|
        output_flag = read_target_file(line, query_ids, ignore_line_mathed_by: ignore_line_mathed_by, sep_target: flags.sep_target, target: "target", column_target: flags.column_target, delete_chars_from_column: flags.delete_chars_from_column, invert_match: flags.invert_match, exact_match: flags.exact_match, ignore_case: flags.ignore_case, sort_output_by_query_flag: sort_output_by_query_flag)
        if output_flag != ""
	  sorted_output[output_flag] = line
	end
      end
    elsif target.match(/.*\.gz$/) # gzip file
      Compress::Gzip::Reader.open(target) do |gfile|
        gfile.each_line do |line|
          output_flag = read_target_file(line, query_ids, ignore_line_mathed_by: ignore_line_mathed_by, sep_target: flags.sep_target, target: target, column_target: flags.column_target, delete_chars_from_column: flags.delete_chars_from_column, invert_match: flags.invert_match, exact_match: flags.exact_match, ignore_case: flags.ignore_case, sort_output_by_query_flag: sort_output_by_query_flag)
          if output_flag != ""
	    sorted_output[output_flag] = line
  	  end
        end
      end
    else # not gzip file
      File.each_line(target) do |line|
        output_flag = read_target_file(line, query_ids, ignore_line_mathed_by: ignore_line_mathed_by, sep_target: flags.sep_target, target: target, column_target: flags.column_target, delete_chars_from_column: flags.delete_chars_from_column, invert_match: flags.invert_match, exact_match: flags.exact_match, ignore_case: flags.ignore_case, sort_output_by_query_flag: sort_output_by_query_flag)
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

  def read_target_file(line : String, query_ids : Hash(String, String), ignore_line_mathed_by : String = "^#", sep_target : String = "\t", target : String = "target", column_target : Int32 = 1, delete_chars_from_column : String = "^>", invert_match : Int32 = 0, exact_match : Int32 = 0, ignore_case : Int32 = 0, sort_output_by_query_flag : Bool = false)
    return false if ignore_line_mathed_by != "" && line.match(/#{ignore_line_mathed_by}/)
    return false if line.match(/^\s*$/)
    arr = line.split(/#{sep_target}/)
    raise "error: #{target} only have #{arr.size} column in line #{line}, but --column_target #{column_target}, try to change --sep_target for line: #{arr}\n" if column_target > arr.size
    output_flag = ""
    id = arr[column_target - 1]
    id = id.gsub(/#{delete_chars_from_column}/, "") if delete_chars_from_column != ""
    id = id.upcase if ignore_case > 0
    if invert_match == 0
      if exact_match >= 1
        if query_ids.has_key?(id)
          if sort_output_by_query_flag
            output_flag = id
          else
            puts "#{line}"
          end
        end
      else
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
      end
    else # flags.invert_match >=1
      if exact_match >= 1
        if !query_ids.has_key?(id)
          puts "#{line}"
        end
      else
        # raise "error: --invert_match #{flags.invert_match} not support --exact_match=#{flags.exact_match}"
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
      end
    end
    return output_flag
  end

  def read_query_file(line : String, column_query : Int32, query_ids : Hash(String, String), ignore_line_mathed_by : String = "", sep_query : String = "\t", query : String = "", delete_chars_from_column : String = "", ignore_case : Int32 = 0)
    return query_ids if ignore_line_mathed_by != "" && line.match(/#{ignore_line_mathed_by}/)
    return query_ids if line.match(/^\s*$/)
    arr = line.split(/#{sep_query}/)
    raise "error: query #{query} only have #{arr.size} columns, but --column_query #{column_query}, try to change --sep_query for line: #{arr}\n" if column_query > arr.size
    id = arr[column_query - 1]
    id = id.gsub(/#{delete_chars_from_column}/, "") if delete_chars_from_column != ""
    id = id.upcase if ignore_case > 0
    unless query_ids.has_key?(id)
      query_ids[id] = ""
    end
    return query_ids
  end
end

GrepFile.run
