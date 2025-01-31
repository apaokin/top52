class Top50BenchmarksController < Top50BaseController

  def index
    @top50_benchmarks = Top50Benchmark.all
  end

  def show
    @top50_benchmark = Top50Benchmark.find(params[:id])
  end
 
  def new
    @top50_benchmark = Top50Benchmark.new
  end

  def create
    @top50_benchmark = Top50Benchmark.new(top50benchmark_params)
    if @top50_benchmark.save
      redirect_to :top50_benchmarks
    else
      render :new
    end
  end

  def edit
    @top50_benchmark = Top50Benchmark.find(params[:id])
  end

  def update
    @top50_benchmark = Top50Benchmark.find(params[:id])
    @top50_benchmark.update_attributes(top50benchmark_params)
    if top50benchmark_params[:is_valid].to_i == 1
      @top50_benchmark.confirm
    end
    redirect_to :top50_benchmarks
  end

  def destroy
    @top50_benchmark = Top50Benchmark.find(params[:id])
    @top50_benchmark.destroy
    redirect_to :top50_benchmarks
  end

  def default
    Top50Benchmark.default!
  end

  private

  def top50benchmark_params
    params.require(:top50_benchmark).permit(:name, :name_eng, :measure_id, :is_valid)
  end
end
