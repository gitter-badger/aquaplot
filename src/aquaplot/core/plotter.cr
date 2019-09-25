require "./title"
require "./plotrange"
require "uuid"

module PlotterModule
  # Helper class to combine the attributes of a gnuplot graph
  # into a valid configuration file to be passed directly to
  # gnuplot.  Also provides helpful class methods to create plots
  # from common gnuplot inputs, such as functions.  Eventually,
  # this should also be the base for Plotter3d
  class Plotter
    # Initializes an empty title object for the graph
    # This provides a more explicit setting of a title
    # by using the method `set_title` to set title
    # configuration options
    property title : TitleModule::Title = TitleModule::Title.new ""

    # Initializes an empty range object for the graph
    # This provides a zero length range which should
    # not be plotted, but allows for an instance to be
    # created and modified without throwing an error
    # for a bad `PlotRange` object
    property range : PlotRangeModule::PlotRange = PlotRangeModule::PlotRange.new 0, 0

    # Stores the final command for a gnuplot.  This should
    # never be edited by a user.  This will always be the
    # final line contained in a gnuplot configuration file
    # before the plot is either saved or displayed.
    private property args : String = ""

    # We can get away with an empty initialization here because
    # all properties are "valid"
    def initialize
    end

    # The more common initialization option, where the argument
    # of a plot is assigned when the instance is initialized.
    def initialize(@args)
    end

    # Class method to create a valid Plotter instance from a function.
    # There is currently nothing stopping a user from inputting a comma
    # delimited string as the function in order to pass multiple plots,
    # but there are other class methods that provide an easier to use
    # interface for that option.  These methods are generally lower level,
    # since eventually users should use a PlotFunction object which will
    # allow for easier passing of parameters to a function, such as fill
    # or other display options.
    def self.from_function(function : String, start : Int32, stop : Int32, **options)
      args = "plot [#{start}:#{stop}] #{function}"
      return Plotter.new args: args
    end

    # Class method to create a valid Plotter instance from an Array of functions.
    # This is the more convenient way for a user to pass multiple functions to
    # create a plot.  Again, this is a lower level function and eventually should
    # be hidden from the user in favor of creating PlotFunction objects to
    # enable better configuration of a plot.
    def self.from_functions(functions : Enumerable(String), start : Int32, stop : Int32, **options)
      args = "plot [#{start}:#{stop}] #{functions.join(',')}"
      return Plotter.new args: args
    end

    # Function to set the title of a graph.  If this is not called, the
    # default empty title of the graph will not be displayed.
    def set_title(label, font = 20, **kwargs)
      @title = TitleModule::Title.new label, font, **kwargs
    end

    # Resets the title of a graph to a default empty graph.  This title will
    # not impact the output.
    def reset_title
      @title = TitleModule::Title.new ""
    end

    # Saves a graph to a given file.  This will overwrite a file if it currently
    # exists.
    def save_fig(fname : String)
      config, id = self.build_opts(fname)
      self.gnuplot_dispatch(config, id)
    end

    # Generic helper function that creates a temporary file in order to
    # pass a configuration file to gnuplot, and then cleans up after itself
    # by deleting the file.  This requires that the script has write access
    # where it is run.
    private def gnuplot_dispatch(config, id)
      File.write(id, config)
      Process.run("gnuplot -p #{id}", shell: true)
      File.delete(id)
    end

    # Currently a rather messy way of creating a configuration file for
    # gnuplot.  Eventually, each piece should override their to_s methods
    # in order to quickly build this file without a messy parsing solution.
    # Ideally this will be moved out of Plotter soon.
    private def build_opts(fname : String = "")
      id = UUID.random.to_s
      config = ""
      if !fname.empty?
        config += "set term png\n"
        config += "set output \"#{fname}\"\n"
      end
      config += @title.add_options
      config += @args
      return config, id
    end

    # Shows a plot using the default gnuplot term.  When I (Chris Zimmerman)
    # wrote this, I had some issues with my display manager showing the
    # graph correctly with the default term, so it may be useful to allow
    # some checking to see if a display manager can be found before this
    # is called.  Also this is a pain with WSL, since an xserver is required
    def show
      config, id = self.build_opts
      self.gnuplot_dispatch(config, id)
    end
  end
end
