alias Task = ->

class Queue
  Log = ::Log.for(self)

  def initialize(@capacity : Int32 = 5, @wait_for = 1.second)
    @tasks = [] of Task
    @done = false
    @close = false
    self.start
  end

  def close
    @close = true
  end

  def done?
    @done
  end

  def empty?
    @tasks.empty?
  end

  def add(&block)
    Log.debug { "Adding a new task..." }
    @tasks << block
  end

  private def start
    Log.info { "Starting queue..." }

    spawn do
      while !empty? || !@close
        Log.debug { "Processing new group... capacity=#{@capacity}" }

        tasks = @tasks.pop(@capacity)
        size = tasks.size

        ready = Channel(Nil).new

        tasks.each do |task|
          spawn do
            begin
              task.call
            ensure
              ready.send nil
            end
          end
        end

        size.times { ready.receive? }

        sleep(@wait_for)
      end

      @done = true
    end
  end
end
