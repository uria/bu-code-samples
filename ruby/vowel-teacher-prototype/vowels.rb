#!/usr/bin/env ruby
require 'gnomecanvas2'

$wavs_duration = "00:00.1"
$graph_update_period = 30 #ms
$pairs = [[500,1300]]
pids = []

$MIN_F1 = 200.0
$MAX_F1 = 800.0
$MIN_F2 = 2500.0
$MAX_F2 = 500.0
$WIDTH = 600.0
$HEIGHT = 600.0

$DOT_RADIUS = 4

class Pronunciation
  attr_accessor :name, :phonemes

  def initialize(name, *phonemes)
    @name = name
    @phonemes = phonemes
  end

  def to_s
    @name
  end
end

class Phoneme
  attr_accessor :f1, :f2, :f3, :symbol

  def initialize(symbol, *fs)
    @symbol = symbol
    @f1, @f2, @f3 = fs
  end
end


$SBE = Pronunciation.new("Southern British English",
                         Phoneme.new("/iː/", 296, 2241),
                         Phoneme.new("/ɪ/", 396, 1839),
                         Phoneme.new("/e/", 532, 1656),
                         Phoneme.new("/æ/", 667, 1565),
                         Phoneme.new("/ʌ/", 661, 1296),
                         Phoneme.new("/ɑː/", 680, 1193),
                         Phoneme.new("/ɒ/", 643, 1019),
                         Phoneme.new("/ɔː/", 480, 857),
                         Phoneme.new("/ʊ/", 395, 1408),
                         Phoneme.new("/uː/", 386, 1587),
                         Phoneme.new("/ɜː/",519, 1408))

$Spanish = Pronunciation.new("Spanish",
                             Phoneme.new("/i/", 286, 2147),
                             Phoneme.new("/e/", 458, 1814),
                             Phoneme.new("/a/", 638, 1353),
                             Phoneme.new("/o/", 460, 1019),
                             Phoneme.new("/u/", 322, 992))


$Pronunciations = [$SBE, $Spanish]

def mean(xs)
  xs.inject(0) { |x,y| x+y } / xs.length
end

#Read formants from Praat generated file.
def readFormants(file)
  f1, f2 = [], []

  fs = []

  File.open(file, "r") do |f|
    # 9 useless lines
    9.times { f.gets }
    while !f.eof?
      #Each block starts with the number of formants found
      f.gets
      how_many = f.gets.to_i
      #We are only interested in the first two formants
      f1 = f.gets.to_f
      f.gets
      f2 = f.gets.to_f
      (1+(how_many-2)*2).times { f.gets}
      fs << [f1,f2]
    end
  end

  fs
end

#Delete formants out of the vowels range
def filterFormants(fs)
  fs.delete_if { |f| f[0] < $MIN_F1 || f[0] > $MAX_F1 || f[1] > $MIN_F2 || f[1] < $MAX_F2}
end

class VowelGraph < Gtk::VBox
  def setup_plot(resize = false)
    @dots = (1..20).collect do |i|
      c = ((255.0**(1.0/20))**i).to_i
      Gnome::CanvasEllipse.new(@canvas.root, {:fill_color_rgba => 0xFF000000+c})
    end.reverse
  end

  def set_targets(pronunciation)
    @targets.each { |w| w.destroy() }
    @targets = []
    pronunciation.phonemes.each do |p|
      x,y = fs_to_canvas(p.f1, p.f2)
      df1 = delta_f1_to_delta_y(p.f1/10)
      df2 = delta_f2_to_delta_x(p.f2/10)
      @targets << Gnome::CanvasEllipse.new(@canvas.root, {:y1 => y-df1, :x1 => x-df2, :y2 => y+df1, :x2 => x+df2,  :fill_color_rgba => 0xFFFFaaFF})
      @targets << Gnome::CanvasEllipse.new(@canvas.root, {:y1 => y-$DOT_RADIUS, :x1 => x-$DOT_RADIUS, :y2 => y+$DOT_RADIUS, :x2 => x+$DOT_RADIUS,  :fill_color_rgba => 0xFFFF00FF})
      @targets << Gnome::CanvasText.new(@canvas.root, {:text => p.symbol,:x => x, :y => y+7, :font => "Sans 10", :anchor => Gtk::ANCHOR_N, :fill_color => "black"})
    end
  end

  def set_dot_center(i,x,y)
    @dots[i].x1 = x-$DOT_RADIUS
    @dots[i].x2 = x+$DOT_RADIUS
    @dots[i].y1 = y-$DOT_RADIUS
    @dots[i].y2 = y+$DOT_RADIUS
    @dots[i].raise_to_top()
  end

  def delta_f1_to_delta_y(delta_f)
    $WIDTH * delta_f / ($MAX_F1 - $MIN_F1)
  end

  def delta_f2_to_delta_x(delta_f)
    $WIDTH * delta_f / ($MAX_F2 - $MIN_F2)
  end

  def fs_to_canvas(f1,f2)
    y = $WIDTH  * (f1 - $MIN_F1) / ($MAX_F1 - $MIN_F1)
    x = $HEIGHT * (f2 - $MIN_F2) / ($MAX_F2 - $MIN_F2)
    [x,y]
  end

  def plot_points()
    setup_plot() unless defined?(@dots)

    @label.set_markup("<small>(#{$pairs.last[0].to_i},#{$pairs.last[1].to_i})</small>")

    $pairs.last(20).reverse.each_with_index do |p,i|
      x,y = fs_to_canvas(*p)
      set_dot_center(i, x, y)
    end
  end

  def initialize()
    super()
    @box = Gtk::EventBox.new
    @targets = []
    @pronunciations = Gtk::ComboBox.new()
    $Pronunciations.each { |p| @pronunciations.append_text(p.to_s)}
    @pronunciations.signal_connect("changed") { set_targets($Pronunciations[@pronunciations.active])}
    pack_start(@box)
    @label = Gtk::Label.new
    pack_end(@label,false,false,0)
    pack_end(@pronunciations,false,false,0)
    set_border_width(@pad = 2)
    set_size_request((@width = 48)+(@pad*2), (@height = 48)+(@pad*2))
    @canvas = Gnome::Canvas.new(true)
    @plot = Gnome::Canvas.new(true)
    @box.add(@canvas)
    @box.add(@plot)
    @pronunciations.set_active(0)
    @box.signal_connect('size-allocate') { |w,e,*b|
      @width, @height = [e.width,e.height].collect{|i|i - (@pad*2)}
      @size = [@width,@height].min
      canvas_size = @size * 0.75
      @canvas.set_size(canvas_size,canvas_size)
      @canvas.set_scroll_region(0, 0, canvas_size, canvas_size)
      false
    }
    signal_connect_after('show') {|w,e| start() }
    signal_connect_after('hide') {|w,e| stop() }
   end

  def start
        @tid= Gtk::timeout_add(30) { plot_points(); true }
  end

  def stop
        Gtk::timeout_remove(@tid) if @tid
        @tid = nil
  end
end

class Viewer < Gtk::Window
  def initialize()
    super()
    set_title("Vowel teacher v0.3")
    signal_connect("delete_event") { |i,a| Gtk::main_quit }
    set_default_size($WIDTH*1.5, $HEIGHT*1.5)
    add(VowelGraph.new)
  end
end

#Returns false if a file is locked by another program
def accesible(f)
  begin
    File.open(f,"r")
    true
  rescue
    false
  end
end

#Executes a block when a file is accesible
def when_accesible(filename, &block)
  until accesible(filename)
    sleep(0.01)
  end
  yield
end

def plot_formants
  Gtk.init()

  view = Viewer.new
  view.show_all

  Gtk.main()
end

def record_wavs
  (1..10000).each do |i|
    system "./record -c -i mic -t 00:00.037 -o ./data/rec#{i}"
  end
end

def analyze_formants_with_praat
  (1..9900).each do |i|
    when_accesible("./data/rec#{i+1}000.wav") { system("praat get_formants.praat #{i}") }
  end
end

def read_formants_from_file_loop
  (1..9900).each do |i|
    when_accesible("./data/fs#{i+1}.Formant") do
      fs = filterFormants(readFormants("./data/fs#{i}.Formant"))
      $pairs.concat(fs)
    end
  end
end

#Init threads and processes
# 1) Records $wavs_duration ms wavs named r000000.wav, r000001.wav, ...
# 2) Executes praat formant analizer (see get_formants.praat) which generates f000000.Formant, f000001.Formant, ...
# 3) Parses the .Formant files and adds its formants to a list of last formants
# 4) Updates the graphic each $graph_update_period ms.

system("rm data/*")

at_exit do
  pids.each { |p| Process.kill("KILL", p) }
end

pids << fork { record_wavs() }
pids << fork { analyze_formants_with_praat() }
Thread.new { read_formants_from_file_loop() }
plot_formants()

