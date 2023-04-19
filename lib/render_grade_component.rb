module RenderGradeComponent
  class TableDecorator
    def decorate0(el, level)
      offset = (level - 1) * 15;
      %[<tr><td colspan="3"><div style="padding-left: #{offset}px;">#{el.strip_markup}</div></td></tr>]
    end

    def decorate(el, level, cnt)
      offset = (level - 1) * 15;
      %[<tr><td><div style="padding-left: #{offset}px;">#{el.strip_markup}</div></td>] + 
      %[<td style="text-align: center;"><%= @grade.score && @grade.score["#{cnt}"] %></td>] +
      %[<td style="text-align: center;"><%= @grade.score && grade_group(@grade.score["#{cnt}"]) %></td></tr>]
    end
  end

  class FormDecorator
    def decorate0(el, level)
      offset = (level - 1) * 15;
      %[<div class="form-group"><div style="padding-left: #{offset}px;"><%= label_tag "", "#{el.strip_markup}", class: "control-label" %></div></div>]
    end

    def decorate(el, level, cnt)
      offset = (level - 1) * 15;
      %[<div class="form-group"><div style="padding-left: #{offset}px;"<%= label_tag "grade[score][#{cnt}]", "#{el.humanize_markup}", class: "control-label col-md-6" %></div>] +
      %[<div class="input-group col-md-1"><%= text_field_tag "grade[score][#{cnt}]", @grade && @grade.score && @grade.score["#{cnt}"], class: "form-control" %>] +
      %[</div></div>]
    end
  end

  class SignificantIndexesDecorator
    def decorate0(el, level)
      ""
    end

    def decorate(el, level, cnt)
      if el =~ /\*\*(P|T)\*\*/
        "#{cnt}_#{$1}"
      else
        ""
      end
    end
  end

  def visit(deco, ary, level, &blk)
    out = ''
    ary.each_with_index do |el,idx|
      if el.is_a? Array
        out += visit(deco, el, level + 1, &blk) + "\n"
      elsif el
       if ary[idx + 1] && ary[idx + 1].is_a?(Array)
          out += deco.decorate0(el, level) + "\n"
        else
          cnt = blk.call(level)
          out += deco.decorate(el, level, cnt) + "\n"
        end
      else
        return ''
      end
    end
    out
  end

  def walk_component(deco, ary)
    depth = 0
    counter = -1
    visit(deco, ary, 0) {|level| depth = level if level > depth; counter += 1 }
    #depth
  end

  def grade_component_as_table(yaml)
    decorator = TableDecorator.new
    walk_component(decorator, YAML.load(yaml))
  end

  def grade_component_as_form(yaml)
    decorator = FormDecorator.new
    walk_component(decorator, YAML.load(yaml))
  end

  def get_significant_indexes(yaml)
    decorator = SignificantIndexesDecorator.new
    x = walk_component(decorator, YAML.load(yaml))
    x.split("\n").reject {|e| e.empty?}.inject({}) do |m,o|
      key, val = o.split("_")
      m[val] ||= []
      m[val].push key
      m
    end
  end
end

class String
  def strip_markup
    self.sub(/\*\*[PT]\*\*/, '')
  end

  def humanize_markup
    self.sub(/\*\*([PT])\*\*/) {|m|
      if $1 == 'P'
        ' (praktek)'
      else
        ' (teori)'
      end
    }
  end
end

if $0 == __FILE__
  require 'yaml'
  require 'pp'
  include RenderGradeComponent

  raise "Please specify yaml" unless ARGV[0]
  ary = YAML.load(File.open(ARGV[0]))
  raise "Not an array" unless ary.is_a? Array
  
  print grade_component_as_table(File.open(ARGV[0]))
  pp get_significant_indexes(File.open(ARGV[0]))
end
