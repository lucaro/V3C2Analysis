using Dates
using DataFrames, CSV
using Gadfly, Cairo, Fontconfig, Compose
using StatsBase, Statistics

theme = Theme(plot_padding = [1mm])

## upload date

seconds_per_week = 7 * 24 * 3600

df = CSV.read("dates.1.csv", DataFrame)
v3c1 = DataFrame(collection = "V3C1", time = map(x -> round(Int, datetime2unix(DateTime(x)) / seconds_per_week / 2) * seconds_per_week * 2, df[:, :date]), count = df[:, :count] ./ sum(df[:, :count]))
df = CSV.read("dates.2.csv", DataFrame)
v3c2 = DataFrame(collection = "V3C2", time = map(x -> round(Int, datetime2unix(DateTime(x)) / seconds_per_week / 2) * seconds_per_week * 2, df[:, :date]), count = df[:, :count] ./ sum(df[:, :count]))

h = innerjoin(v3c1, v3c2, on = :time, makeunique=true)


df = combine(groupby(vcat(v3c1, v3c2), [:time, :collection]), :count => sum)

p = plot(df, x = :time, y = :count_sum, color = :collection, Geom.line,
Stat.xticks(ticks=[datetime2unix(DateTime("$(y)-01-01")) for y in 2006:2018]), Stat.yticks(ticks=collect(0:0.002:0.012)),
Scale.x_continuous(labels=x -> Dates.format(unix2datetime(x), "yyyy")), Scale.y_continuous(labels = x -> "$(x * 1000) ‰"),
Guide.XLabel(""), Guide.YLabel("Relative upload rate", orientation=:vertical), Guide.colorkey(title = "Collection"), theme)

draw(PDF("upload_hist.pdf", 10cm, 4.5cm), p)


##resolution

res_ticks = [(320,240), (640, 360), (640, 480), (960,540), (960,720), (1280, 720), (1280,960), (1920, 1080)]
tic_dict = Dict{Number, Tuple}()
for t in res_ticks tic_dict[reduce(*, t)] = t end

df = CSV.read("resolution.1.csv", DataFrame)
v3c1 = DataFrame(collection = "V3C1", count = df[:, :count] ./ sum(df[:, :count]), pixels = df[:, :width] .* df[:, :height])
df = CSV.read("resolution.2.csv", DataFrame)
v3c2 = DataFrame(collection = "V3C2", count = df[:, :count] ./ sum(df[:, :count]), pixels = df[:, :width] .* df[:, :height])

h = innerjoin(v3c1, v3c2, on = :pixels, makeunique=true)
cor(h[:, :count], h[:, :count_1])

df = combine(groupby(vcat(v3c1, v3c2), [:pixels, :collection]), :count => sum)

p = plot(df, y = :count_sum, x = :pixels, color = :collection, Geom.line,
Coord.cartesian(xmax=2.2e6),
Stat.yticks(ticks = map(sqrt, [1e-3, 1e-2, 5e-2, 1e-1, 2e-1, 5e-1])), Scale.y_sqrt(labels = x ->(v = ((x^2) * 10000); "$(round(Int, v) / 100) %")),
Stat.xticks(ticks = collect(keys(tic_dict))), Guide.xticks(orientation=:vertical),
Scale.x_continuous(labels = x -> (t = tic_dict[x]; return "$(t[1])×$(t[2])")),
Guide.XLabel(""),#Guide.XLabel("Video resolution in pixels"),
Guide.YLabel("Fraction of videos", orientation=:vertical), Guide.colorkey(title = "Collection"), Theme(plot_padding = [2mm, -1mm, 2mm, -3mm])
)

draw(PDF("resolution_hist.pdf", 10cm, 5cm), p)


## segment duration

df = CSV.read("segment_duration.1.csv", DataFrame)
df[:, :duration]= round.(df[:, :duration]; digits = 1)
df = combine(groupby(df, :duration), :count => sum)
v3c1 = DataFrame(collection = "V3C1", count = df[:, :count_sum] ./ sum(df[:, :count_sum]), duration = df[:, :duration])

df = CSV.read("segment_duration.2.csv", DataFrame)
df[:, :duration]= round.(df[:, :duration]; digits = 1)
df = combine(groupby(df, :duration), :count => sum)
v3c2 = DataFrame(collection = "V3C2", count = df[:, :count_sum] ./ sum(df[:, :count_sum]), duration = df[:, :duration])

h = innerjoin(v3c1, v3c2, on = :duration, makeunique=true)
cor(h[:, :count], h[:, :count_1])


df = vcat(v3c1, v3c2)

p = plot(df, x = :duration, y = :count, color = :collection, Geom.line, Coord.cartesian(xmin = 0, xmax = 50, ymin = -6, ymax = -1),  Scale.y_log10,
Guide.XLabel(""), Guide.YLabel("Fraction of segments", orientation = :vertical), Guide.colorkey(title = "Collection"), theme)

draw(PDF("segment_duration_hist.pdf", 10cm, 4.5cm), p)


## video duration

df = CSV.read("duration.1.csv", DataFrame)
df[:, :duration_min]= round.(df[:, :duration] / 60.0; digits = 2)
df = combine(groupby(df, :duration_min), :count => sum)
v3c1 = DataFrame(collection = "V3C1", count = df[:, :count_sum] ./ sum(df[:, :count_sum]), duration = df[:, :duration_min])
v3c1 = sort(v3c1, :duration)
v3c1[:, :cumsum] = cumsum(v3c1[:, :count])

df = CSV.read("duration.2.csv", DataFrame)
df[:, :duration_min]= round.(df[:, :duration] / 60.0; digits = 2)
df = combine(groupby(df, :duration_min), :count => sum)
v3c2 = DataFrame(collection = "V3C2", count = df[:, :count_sum] ./ sum(df[:, :count_sum]), duration = df[:, :duration_min])
v3c2 = sort(v3c2, :duration)
v3c2[:, :cumsum] = cumsum(v3c2[:, :count])

h = innerjoin(v3c1, v3c2, on = :duration, makeunique=true)
cor(h[:, :count], h[:, :count_1])
cor(h[:, :cumsum], h[:, :cumsum_1])

df = vcat(v3c1, v3c2)

p = plot(df, x = :duration, y = :cumsum, color = :collection, Geom.line, Coord.cartesian(xmin = 0, xmax = 60, ymin = 0, ymax = 1),
	Guide.YTicks(ticks = collect(0:0.1:1)), Scale.y_continuous(labels = x -> "$(round(Int, 100 * x))%"),
    Guide.XLabel(""), Guide.YLabel("Cumulative fraction", orientation = :vertical), Guide.colorkey(title = "Collection"), theme)

draw(PDF("video_duration.pdf", 10cm, 4.5cm), p)


## vimeo category

df = CSV.read("category.1.csv", DataFrame)
v3c1 = DataFrame(collection = "V3C1", count = df[:, :count] ./ sum(df[:, :count]), category = df[:, :category])
df = CSV.read("category.2.csv", DataFrame)
v3c2 = DataFrame(collection = "V3C2", count = df[:, :count] ./ sum(df[:, :count]), category = df[:, :category])

h = innerjoin(
	DataFrame(category = sort(v3c1, :count, rev = true)[:, :category], rank = collect(1:size(v3c1,1))),
	DataFrame(category = sort(v3c2, :count, rev = true)[:, :category], rank = collect(1:size(v3c2,1))),
	on = :category, makeunique=true)
	
corspearman(h[:, :rank], h[:, :rank_1])

df = vcat(v3c1, v3c2)
df[:, :category] = map(x -> x[13:end], df[:, :category])
df = sort(df, :count, rev = true)

p = plot(df[1:20, :], x = :category, y = :count, color = :collection, Geom.bar(position = :dodge),
       Guide.XLabel(""), Guide.YLabel("Fraction of all videos", orientation=:vertical), Guide.colorkey(title = "Collection"),
       Scale.y_continuous(labels = x -> "$(round(Int, 100 * x))%"), Theme(bar_spacing = 1mm, plot_padding = [2mm, 0mm, 2mm, -3mm]))

draw(PDF("category_hist.pdf", 10cm, 6.5cm), p)



## semantic distances

total = CSV.read("distances/total.csv", DataFrame)
v3c1 = CSV.read("distances/v3c1.csv", DataFrame)
v3c2 = CSV.read("distances/v3c2.csv", DataFrame)

df = vcat(
DataFrame(collection = "V3C1", dist = v3c1[:, :dist] ./ 1000, count = v3c1[:, :count_sum]),
DataFrame(collection = "V3C2", dist = v3c2[:, :dist] ./ 1000, count = v3c2[:, :count_sum]),
DataFrame(collection = "V3C1 + V3C2", dist = total[:, :dist] ./ 1000, count = total[:, :count_sum])
)

h = df[df[:, :collection] .== "V3C1", :]
mean(h[:, :dist], weights(h[:, :count])) #45.917683444097236
std(h[:, :dist], weights(h[:, :count])) #6.492919349371129

h = df[df[:, :collection] .== "V3C2", :]
mean(h[:, :dist], weights(h[:, :count])) #46.22709575581058
std(h[:, :dist], weights(h[:, :count])) #6.489823152880049

h = df[df[:, :collection] .== "V3C1 + V3C2", :]
mean(h[:, :dist], weights(h[:, :count])) #46.09621236345112
std(h[:, :dist], weights(h[:, :count])) #6.491085271947892

p = plot(df, x = :dist, y = :count, color = :collection, Geom.line, Coord.cartesian(xmin = 0, xmax = 110),
Guide.XTicks(ticks = collect(0:10:110)), Guide.XLabel("Pairwise L1-Distance"), Guide.YLabel("Count"), Guide.colorkey(title = "Collection"), theme)
draw(PDF("l1_dist_hist.pdf", 10cm, 6cm), p)



##ASR

df = CSV.read("asr_statistics.csv", DataFrame)
wordrate = ceil.(df[:, :wordcount] ./df[:, :speechtime] .* 60)
cmap = countmap(wordrate)
k = collect(keys(cmap))
hist = DataFrame(wpm = k, count = map(x -> cmap[x], k))
p = plot(hist, x = :wpm, y = :count, Geom.bar, Guide.XLabel(""), Guide.YLabel("Count"), Coord.cartesian(xmin = 1, ymin = 0, xmax = 220, ymax = 1200), theme)
draw(PDF("wpm.pdf", 10cm, 5cm), p)



##OCR

#df = CSV.read("textcount.csv", DataFrame)
#p = plot(df, x = :segments, y = :count, Geom.bar(), Coord.cartesian(xmin = 0, xmax = 500, ymin = 0, ymax = 350), Guide.XLabel("Key-frames with Text per Video"), Guide.YLabel("Count"))

df = CSV.read("segment_ocr_count.csv", DataFrame)
p = plot(df, x = :text_fraction, Geom.histogram(bincount = 100), Guide.XTicks(ticks = collect(0:0.1:1)), Scale.x_continuous(labels = x -> "$(round(Int, x * 100)) %"), Guide.XLabel(""), Guide.YLabel("Videos"), theme)

draw(PDF("ocr_hist.pdf", 10cm, 6cm), p)


df = CSV.read("text_per_frame.csv", DataFrame)
p = plot(df, x = :segments, y = :count, Geom.bar(), Guide.XLabel(""), Guide.YLabel("Count"), Scale.y_log10, Coord.cartesian(xmin = 0, xmax = 600), theme)
draw(PDF("text_per_frame_hist.pdf", 10cm, 5cm), p)



##Faces

df = CSV.read("V3C2-faces.csv/V3C2-faces.csv", DataFrame)
h = countmap(df[:, 2])
k = collect(keys(h))
df = DataFrame(faces = k, count = map(x -> h[x], k))
df = sort(df, :count, rev = true)
df[:, :cumsum] = cumsum(df[:, :count])

plot(df, x = :faces, y = :cumsum, Geom.line)

