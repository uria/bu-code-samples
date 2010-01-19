# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def logged_in?
    session[:user]
  end

  def user_is_log_owner?
    logged_in? && params[:log_name] && params[:log_name].casecmp(session[:user].login) == 0
  end

  # Toma un array de sets de entrenamiento y devuelve un array de arrays, con los sets contiguos con el mismo ejercicio juntos
  #Ej : [ curl, curl, squat, squat, curl, squat] -> [[curl, curl], [squat, squat], [curl], [squat]]
  def partitionize(array)
    p = Array.new

    array.each_with_index do |x, i|
      if i == 0 || x.exercise_id != array[i-1].exercise_id
        p << Array.new
      end
      p.last << x
    end
    p
  end

  def  pagination_links_with_tags(paginator, options={}, html_options={})
    pagination_links(@pages, options.merge(:params => {:tagged => @params[:tagged]}), html_options)
  end

  def javascript_preferred_units
    '<script type="text/javascript">var metric_system = '+(log_owner.metric_system()?"true":"false")+';</script>'
  end

  def weight_with_units(weight, decimal_places=2)
    weight_without_units(weight, decimal_places) + (log_owner.metric_system()?" kg.":" lbs.")
  end

  def weight_without_units(weight, decimal_places=2)
      sprintf("%.#{decimal_places}f",weight*(log_owner.metric_system()?0.45359237:1)).gsub(/(\.[1-9]*)0+$/,'\1').gsub(/\.$/,'')
  end

  def intensity_as_1rm_percentage(p1RM)
    sprintf("%.1f%%", p1RM*100)
  end

  def intensity_as_xrm(p1RM)
    if p1RM>1
      return ">1RM";
    elsif p1RM>0.96
      return "1RM";
    elsif p1RM<=0
      return "?RM";
    else
      rm = ((1/p1RM-1)/0.0333)
      return sprintf("%dRM", rm.round)
    end
  end

  def short_date(date)
    sprintf("%d/%d/%d",date.month, date.day, date.year)
  end

  def escape_javascript(javascript)
    (javascript || '').gsub(/["'\/\\]/) { |m| "\\#{m}" }.gsub(/\r\n|\n|\r/, "\\n")
  end

  def show_tags(tags, url_for_options = {})
    if tags.any?
      content_tag('span',
          '[' + tags.collect {|t| link_to(h(t), {:action=>'index', :tagged=>t}.merge(url_for_options), {:rel => "tag"})}.join(' ') + ']' ,
           'class' => 'tags')
    else
      return ""
    end
  end

  def display_avatar
  if @log_owner && @log_owner.avatar_image
      link_to image_tag(url_for_file_column('log_owner', 'avatar_image'), {:class=>"avatar", :alt=>"Avatar", :width=>"64", :height=>"64"}), {:controller => 'profile', :action => 'show'}
    else
      return ''
    end
  end

  def button(text, options, icon = nil, html_options={}, *parameters_for_method_reference)
    text = tag("img", {:width => 16, :height => 16, :alt => icon, :class => 'icon', :src => '/images/icons/'+icon}) + text if !icon.nil?
    link_to(text, options, html_options.update({:class => 'button'}), parameters_for_method_reference)
  end

  def bigbutton(text, options, icon = nil, html_options={}, *parameters_for_method_reference)
    text = tag("img", {:width => 22, :height => 22, :alt => icon, :class => 'icon_', :src => '/images/icons/'+icon}) + text if !icon.nil?
    link_to(text, options, html_options.update({:class => 'bigbutton'}), parameters_for_method_reference)
  end

  def icon(icon, options = nil, html_options={})
      html_opts = {:width => 16, :height => 16, :alt => icon, :class => 'icon', :src => '/images/icons/'+icon}.merge(html_options)
      text = tag("img", html_opts)
      unless options.nil?
        link_to(text, options)
      else
        text
      end
  end

  def requieres_javascript(msg = "This web page requires Javascript for correct operation.")
    content_tag("script", "", {:type => "text/javascript"}) <<
    content_tag("noscript",
      content_tag("div",
        content_tag("p", msg <<
          content_tag("a", " Please enable Javascript.", {:href => url_for(:controller => "/entrance", :action => "how_to_enable_javascript")})),
      {:class => "error"})
    )
  end

  def comments_count(obj)
    unless obj.users_comments_count <= 0
      content_tag('span', "(#{pluralize(obj.users_comments_count, 'comment', 'comments')})", {:class => 'comments-count'})
    end
  end

  ALLOWED_TAGS = %w(blockquote img)

  def whitelist(html)
    if html.index("<")
      tokenizer = HTML::Tokenizer.new(html)
      new_text = ""
      while token = tokenizer.next
        node = HTML::Node.parse(nil, 0, 0, token, false)
        new_text << case node
          when HTML::Tag
            if ALLOWED_TAGS.include?(node.name)
              node.to_s
            else
              node.to_s.gsub(/</, "&lt;")
            end
          else
            node.to_s.gsub(/</, "&lt;")
          end
      end
        html = new_text
    end
      html
  end

  BLACKLISTED_TAGS = %w(i'm im me not by for to do don't the cant can't a dont i've i you he is her she his and of 1 2 3 4 5 6 7 8 9 0)

  def tag_cloud(tag_cloud, category_list)
    max, min = 0, 0
    tag_cloud.delete_if {|x| BLACKLISTED_TAGS.include?(x['name'])}
    tag_cloud.each do |t|
      i = t['count'].to_i
      max = i if i > max
      min = i if i < min
    end

    divisor = ((max - min) / category_list.size) + 1

    tag_cloud.each do |t|
      yield t['name'], category_list[(t['count'].to_i - min) / divisor]
    end
  end

  def private_icon(private)
    if private
      tag("img", {:width => 16, :height => 16, :alt => "Private entry", :class => 'icon', :src => '/images/icons/key.gif'})
    else
      ''
    end
  end

  # AJAXified pagination
  def pagination_links_remote(paginator, page_options={}, ajax_options={}, html_options={})
    pagination_links_each(paginator, page_options) {|page|
      ajax_options[:url].merge!({:page => page})
      link_to_remote(page, ajax_options, html_options)}
  end
end
