# Upgradability stats scripts extracted from top50_machines.js.coffee
# Contains heatmaps, bar plots, tables, and matrix visualizations for stats sections.

getMaxRank = () -> (typeof window != "undefined" && window.TOP50_MAX_RANK) || 50
# Reference edition count
BASE_EDITIONS = 38
# Heatmap cell size (px): 1000/40 × 600/50; heatmaps scale with editions/ranks to keep this cell size
HEATMAP_CELL_WIDTH = 25
HEATMAP_CELL_HEIGHT = 12
HEATMAP_MIN_WIDTH = 300
HEATMAP_MIN_HEIGHT = 240

# Upgradability heatmap native <title> tooltips: server sends machine_name = name || org || "н/д"
heatmapTooltipMachineLabel = (d) ->
  nm = d.machine_name
  if nm? and String(nm).trim() != "" then String(nm).trim() else "н/д"

heatmapTooltipSystemLine = (d) ->
  lines = []
  if d.machine_id != null and d.machine_id != undefined
    lines.push "Система: #{heatmapTooltipMachineLabel(d)}"
  if d.area_name?
    lines.push "Область: #{d.area_name}"
  return "" if lines.length == 0
  "\n" + lines.join("\n")

# Stroke colors for cross-edition highlight; matches stats/area when area_color is set server-side
heatmapAreaStrokeColors = (d) ->
  if d.area_color?
    inner = d.area_color
    if typeof d3 != "undefined" and d3.color?
      c = d3.color(d.area_color)
      inner = c.brighter(0.55).hex() if c?
    { outer: d.area_color, inner: inner }
  else
    { outer: "#000", inner: "#ffeb3b" }

clearMachineHoverHighlight = (containerId) ->
  root = d3.select("##{containerId}")
  root.selectAll(".cell").classed("cell-same-machine", false)
  root.selectAll(".cell .cell-hl-outer").style("stroke", "none")
  root.selectAll(".cell .cell-hl-inner").style("stroke", "none")

applyMachineHoverHighlight = (containerId, d, keyFn) ->
  k = keyFn(d)
  root = d3.select("##{containerId}")
  root.selectAll(".cell").each((d2) ->
    k2 = keyFn(d2)
    same = k2 != null and k2 != undefined and k2 == k
    cell = d3.select(this)
    cell.classed("cell-same-machine", same)
    cols = if same then heatmapAreaStrokeColors(d2) else { outer: "none", inner: "none" }
    cell.select(".cell-hl-outer").style("stroke", cols.outer).style("stroke-width", 3)
    cell.select(".cell-hl-inner").style("stroke", cols.inner).style("stroke-width", 2)
  )

buildEditionRankDomains = (data, options = {}) ->
  data = data or []
  data = [] unless Array.isArray(data)
  rankSource = options.rankSourceData
  rankSource = data unless Array.isArray(rankSource)
  editionSort = options.editionSort or ((a, b) -> b - a)
  rankSort = options.rankSort or ((a, b) -> b - a)
  editions = Array.from(new Set(data.map((d) -> d.edition))).sort(editionSort)
  allRanks = Array.from(new Set(rankSource.map((d) -> d.rank))).filter((r) -> r?).sort(rankSort)
  fallbackRankAscending = options.fallbackRankAscending or false
  if allRanks.length > 0
    ranks = allRanks
  else if fallbackRankAscending
    ranks = Array.from({ length: getMaxRank() }, (_, i) -> i + 1)
  else
    ranks = Array.from({ length: getMaxRank() }, (_, i) -> getMaxRank() - i)
  { editions, ranks }

resolveHeatmapSize = (editions, rankCount, options = {}) ->
  margin = options.margin or { top: 20, right: 20, bottom: 80, left: 60 }
  sizeFn = options.sizeResolver
  if typeof sizeFn == "function"
    size = sizeFn(editions, rankCount)
    return { width: size.width, height: size.height, margin: size.margin or margin }
  edCount = editions.length or 1
  rows = rankCount or 1
  width = Math.max(edCount * HEATMAP_CELL_WIDTH, HEATMAP_MIN_WIDTH)
  height = Math.max(rows * HEATMAP_CELL_HEIGHT, HEATMAP_MIN_HEIGHT)
  { width, height, margin }

buildHeatmapScaffold = (opts = {}) ->
  container = d3.select("##{opts.containerId}")
  return null if opts.requireContainer and container.empty()
  unless opts.clearContainer == false
    container.selectAll("*").remove()
  domains = buildEditionRankDomains(opts.data, {
    rankSourceData: opts.rankSourceData
    editionSort: opts.editionSort
    rankSort: opts.rankSort
    fallbackRankAscending: opts.fallbackRankAscending
  })
  size = resolveHeatmapSize(domains.editions, domains.ranks.length, {
    margin: opts.margin
    sizeResolver: opts.sizeResolver
  })
  width = size.width
  height = size.height
  margin = size.margin
  xRange = if typeof opts.xRange == "function" then opts.xRange(width, height) else if opts.xRange? then opts.xRange else [width, 0]
  yRange = if typeof opts.yRange == "function" then opts.yRange(width, height) else if opts.yRange? then opts.yRange else [height, 0]
  extraBottom = if opts.extraBottom? then opts.extraBottom else 70
  x = d3.scaleBand().range(xRange).domain(domains.editions).padding(0.05)
  y = d3.scaleBand().range(yRange).domain(domains.ranks).padding(0.05)
  svg = container.append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom + extraBottom)
    .append("g")
    .attr("transform", "translate(#{margin.left}, #{margin.top})")
  if opts.drawAxes != false
    xAxis = svg.append("g").attr("transform", "translate(0, #{height})")
    axisBottom = d3.axisBottom(x)
    if typeof opts.xTickFormat == "function"
      axisBottom = axisBottom.tickFormat(opts.xTickFormat)
    xAxis.call(axisBottom)
    xAxis.selectAll("text")
      .attr("transform", "rotate(#{opts.xLabelRotate or -45})")
      .style("text-anchor", "end")
    svg.append("text")
      .attr("x", width / 2)
      .attr("y", height + 55)
      .attr("text-anchor", "middle")
      .style("font-size", "16px")
      .text(opts.xLabel or "Редакция")
    svg.append("g").call(d3.axisLeft(y))
    svg.append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", -margin.left + 20)
      .attr("x", -height / 2)
      .attr("text-anchor", "middle")
      .style("font-size", "16px")
      .text(opts.yLabel or "Ранг")
  { container, svg, x, y, width, height, margin, editions: domains.editions, ranks: domains.ranks }

appendHeatmapHighlightRects = (cells, x, y) ->
  cells.append("rect")
    .attr("class", "cell-hl-outer")
    .attr("x", (d) -> x(d.edition))
    .attr("y", (d) -> y(d.rank))
    .attr("width", x.bandwidth())
    .attr("height", y.bandwidth())
    .attr("fill", "none")
    .attr("stroke", "none")
    .attr("stroke-width", 3)
  cells.append("rect")
    .attr("class", "cell-hl-inner")
    .attr("x", (d) -> x(d.edition) + 2)
    .attr("y", (d) -> y(d.rank) + 2)
    .attr("width", x.bandwidth() - 4)
    .attr("height", y.bandwidth() - 4)
    .attr("fill", "none")
    .attr("stroke", "none")
    .attr("stroke-width", 2)

bindHeatmapMachineHover = (cells, containerId, keyFn = null) ->
  key = keyFn or ((d) -> if d.machine_key? then d.machine_key else d.machine_id)
  cells.filter((d) -> key(d) != null)
    .on("mouseenter", (d) ->
      applyMachineHoverHighlight(containerId, d, key)
    )
    .on("mouseleave", ->
      clearMachineHoverHighlight(containerId)
    )

appendBasicHeatmapCells = (opts = {}) ->
  validData = (opts.data or []).filter((d) -> d.lag != null)
  cells = opts.svg.selectAll(".cell")
    .data(validData)
    .enter().append("g")
    .attr("class", "cell")
  cells.append("rect")
    .attr("class", "cell-fill")
    .attr("x", (d) -> opts.x(d.edition))
    .attr("y", (d) -> opts.y(d.rank))
    .attr("width", opts.x.bandwidth())
    .attr("height", opts.y.bandwidth())
    .attr("fill", opts.fillFn or ((d) -> opts.colorScale(d.lag)))
    .attr("stroke", "#000")
    .attr("stroke-width", 0.5)
  if typeof opts.contourStrokeFn == "function"
    cells.append("rect")
      .attr("class", "cell-contour-sign")
      .attr("x", (d) -> opts.x(d.edition))
      .attr("y", (d) -> opts.y(d.rank))
      .attr("width", opts.x.bandwidth())
      .attr("height", opts.y.bandwidth())
      .attr("fill", "none")
      .attr("stroke", opts.contourStrokeFn)
      .attr("stroke-width", opts.contourStrokeWidth or 2.5)
  appendHeatmapHighlightRects(cells, opts.x, opts.y)
  bindHeatmapMachineHover(cells, opts.containerId, opts.keyFn) unless opts.enableHover == false
  if typeof opts.titleFn == "function"
    cells.append("title").text(opts.titleFn)
  if typeof opts.afterCells == "function"
    opts.afterCells(cells)
  cells

appendGradientLegend = (svg, options = {}) ->
  legendWidth = options.legendWidth or 300
  legendHeight = options.legendHeight or 20
  legendX = options.legendX
  legendX = options.width / 2 - legendWidth / 2 if legendX == null or legendX == undefined
  legendY = options.legendY
  legendY = options.height + 75 if legendY == null or legendY == undefined
  gradientId = options.gradientId or "legend-gradient"
  colors = options.colors or LAG_RAINBOW or ["#00FF00", "#FFFF00", "#FFA500", "#FF0000", "#0000FF", "#800080"]
  defs = svg.append("defs")
  grad = defs.append("linearGradient").attr("id", gradientId).attr("x1", "0%").attr("x2", "100%").attr("y1", "0%").attr("y2", "0%")
  for i in [0...colors.length]
    grad.append("stop").attr("offset", (100 * i / (colors.length - 1)) + "%").attr("stop-color", colors[i])
  legend = svg.append("g").attr("class", "legend").attr("transform", "translate(#{legendX}, #{legendY})")
  legend.append("rect")
    .attr("width", legendWidth)
    .attr("height", legendHeight)
    .style("fill", "url(##{gradientId})")
    .attr("stroke", options.strokeColor or "#333")
    .attr("stroke-width", options.strokeWidth or 0.5)
  legend.append("text")
    .attr("x", 0)
    .attr("y", legendHeight + 14)
    .attr("text-anchor", "start")
    .style("font-size", "12px")
    .style("fill", options.leftColor or "#333")
    .text(options.leftLabel or "")
  legend.append("text")
    .attr("x", legendWidth)
    .attr("y", legendHeight + 14)
    .attr("text-anchor", "end")
    .style("font-size", "12px")
    .style("fill", options.rightColor or "#333")
    .text(options.rightLabel or "")
  legend

prepareChartContainers = (src_id) ->
  container = d3.select("##{src_id}")
  container.selectAll("*").remove()
  headerEl = document.getElementById(src_id + "_header")
  headerContainer = if headerEl then d3.select(headerEl) else container
  if headerEl then headerContainer.selectAll("*").remove()
  { container, headerContainer }

appendChartHeader = (headerContainer, title, marginBottom = "10px") ->
  headerContainer.append("div")
    .text(title)
    .style("font-family", "Arial")
    .style("font-size", "24px")
    .style("font-weight", "500")
    .style("text-align", "center")
    .style("margin-bottom", marginBottom)

appendYAxisLabel = (svg, marginLeft, height, y_label) ->
  svg.append("text")
    .attr("transform", "rotate(-90)")
    .attr("y", marginLeft - 70)
    .attr("x", 0 - (height / 2))
    .attr("dy", "1em")
    .style("text-anchor", "middle")
    .style("font-family", "Arial")
    .style("font-size", "14px")
    .text(y_label)

applyMatrixCellVisibility = (cellGroup, d, activeFilters, statusColors, x, y) ->
  leftActive = d.new_upd_status and activeFilters[d.new_upd_status]
  rightActive = d.pos_status and activeFilters[d.pos_status]
  cellWidth = x.bandwidth()
  if (leftActive) and (rightActive)
    cellGroup.select(".left-half")
      .attr("x", x(d.edition))
      .attr("width", cellWidth / 2)
      .attr("fill", statusColors[d.new_upd_status])
      .attr("visibility", "visible")
    cellGroup.select(".right-half")
      .attr("x", x(d.edition) + cellWidth / 2)
      .attr("width", cellWidth / 2)
      .attr("fill", statusColors[d.pos_status])
      .attr("visibility", "visible")
  else if leftActive
    cellGroup.select(".left-half")
      .attr("x", x(d.edition))
      .attr("width", cellWidth)
      .attr("fill", statusColors[d.new_upd_status])
      .attr("visibility", "visible")
    cellGroup.select(".right-half").attr("visibility", "hidden")
  else if rightActive
    cellGroup.select(".left-half")
      .attr("x", x(d.edition))
      .attr("width", cellWidth)
      .attr("fill", statusColors[d.pos_status])
      .attr("visibility", "visible")
    cellGroup.select(".right-half").attr("visibility", "hidden")
  else
    cellGroup.selectAll("rect").attr("visibility", "hidden")
  if leftActive or rightActive
    cellGroup.selectAll(".cell-hl-outer, .cell-hl-inner").attr("visibility", "visible")
  else
    cellGroup.selectAll(".cell-hl-outer, .cell-hl-inner").attr("visibility", "hidden")
  { leftActive, rightActive }


drawLegend = (svg, colorScale, minLag, maxLag, width, height) ->
  appendGradientLegend(svg, {
    width: width
    height: height
    gradientId: "legend-gradient"
    colors: ["#00FF00", "#FFFF00", "#FFA500", "#FF0000", "#0000FF", "#800080"]
    leftLabel: d3.format(".2f")(minLag) + " дн."
    rightLabel: d3.format(".2f")(maxLag) + " дн."
    strokeColor: "none"
    strokeWidth: 0
  })

drawHeatmap = (data, containerId, title) ->
  scaffold = buildHeatmapScaffold({
    containerId: containerId
    data: data
    extraBottom: 70
    xTickFormat: (d) ->
      if typeof editionDatesLag != "undefined" && editionDatesLag && editionDatesLag[d - 1] then editionDatesLag[d - 1] else d
  })
  return unless scaffold?
  { svg, x, y, width, height } = scaffold

  # Определяем минимальное и максимальное значение lag
  minLag = d3.min(data, (d) -> d.lag)
  maxLag = d3.max(data, (d) -> d.lag)
  if minLag == null or maxLag == null
    minLag = 0
    maxLag = 1

  # Создаём цветовую шкалу
  colorScale = d3.scaleSequential((d3.interpolateRgbBasis(["#00FF00", "#FFFF00", "#FFA500", "#FF0000", "#0000FF", "#800080"])))
    .domain([minLag, maxLag])
  appendBasicHeatmapCells({
    svg: svg
    data: data
    x: x
    y: y
    containerId: containerId
    colorScale: colorScale
    titleFn: (d) ->
      info = "#{title}\nРедакция: #{d.edition}, Место: #{d.rank}, Задержка: #{d.lag} дн."
      info += heatmapTooltipSystemLine(d)
      info
  })

  # Рисуем легенду
  drawLegend(svg, colorScale, minLag, maxLag, width, height)

# Transform linear lag data to another scale (computed client-side to reduce payload)
transformLagData = (data, method) ->
  if method == "linear"
    data
  else
    data.map((d) ->
      out = { edition: d.edition, rank: d.rank, lag: if d.lag == null then null else (
        switch method
          when "log_shifted" then Math.log(d.lag + 1)
          when "bidirectional" then (if d.lag > 0 then Math.log(d.lag + 1) else -Math.log(Math.abs(d.lag) + 1))
          when "sqrt" then Math.sqrt(Math.abs(d.lag)) * (if d.lag < 0 then -1 else 1)
          else d.lag
      ) }
      out.machine_id = d.machine_id if d.machine_id != null
      out.machine_name = d.machine_name if d.machine_name != null
      out.machine_key = d.machine_key if d.machine_key != null
      out.area_name = d.area_name if d.area_name?
      out.area_color = d.area_color if d.area_color?
      out
    )

# Build CSV from lag data (rows=rank, cols=edition). inQuarters: export values as quarters (lag/91.25)
buildEditionRankGridCsv = (data, valueResolver, valueFormatter, rankList = null) ->
  editions = Array.from(new Set((data or []).map((d) -> d.edition))).sort((a, b) -> a - b)
  ranks = rankList or Array.from({ length: getMaxRank() }, (_, i) -> i + 1)
  lookup = {}
  (data or []).forEach((d) ->
    resolved = valueResolver(d)
    if resolved != null and resolved != undefined
      lookup["#{d.edition}-#{d.rank}"] = resolved
  )
  header = "Место | Редакция," + editions.join(",")
  rows = ranks.map((rank) ->
    cells = editions.map((ed) ->
      valueFormatter(lookup["#{ed}-#{rank}"])
    )
    rank + "," + cells.join(",")
  )
  [header].concat(rows).join("\n")

buildLagCsv = (data, inQuarters = false) ->
  fmt = (v) -> if v == null or v == undefined then "" else (if inQuarters then (if Math.abs(v) >= 10 then Math.round(v) else d3.format(".2f")(v)) else v)
  buildEditionRankGridCsv(data, ((d) -> if inQuarters then d.lag / DAYS_PER_QUARTER else d.lag), fmt)

LAG_RAINBOW = ["#00FF00", "#FFFF00", "#FFA500", "#FF0000", "#0000FF", "#800080"]
DAYS_PER_QUARTER = 91.25
lagFormatDay = (d) -> Math.round(d).toString()
lagFormatQuarter = (q) -> (if Math.abs(q) >= 10 then Math.round(q) else d3.format(".1f")(q)).toString()
lagFlexibleScale = (data, method) ->
  data = data or []
  data = [] unless Array.isArray(data)
  vals = data.map((d) -> d.lag).filter((v) -> v != null && v != undefined)
  if vals.length == 0
    scale = d3.scaleLinear().domain([0, 1]).range(LAG_RAINBOW).clamp(true)
    return { colorScale: scale, minLag: 0, maxLag: 1, inQuarters: false }
  method = (method and method.toString()) or "plain"
  inQuarters = (method == "quarters")
  if inQuarters
    vals = vals.map((v) -> v / DAYS_PER_QUARTER)
  minLag = d3.min(vals)
  maxLag = d3.max(vals)
  if minLag >= maxLag then maxLag = minLag + 1
  if method == "log"
    transform = (v) -> (if v >= 0 then 1 else -1) * Math.log(1 + Math.abs(v))
    tVals = vals.map(transform)
    tMin = d3.min(tVals)
    tMax = d3.max(tVals)
    if tMin >= tMax then tMax = tMin + 1
    colorScale = d3.scaleSequential(d3.interpolateRgbBasis(LAG_RAINBOW)).domain([tMin, tMax])
    toColor = if inQuarters then ((v) -> colorScale(transform(v / DAYS_PER_QUARTER))) else ((v) -> colorScale(transform(v)))
    return { colorScale: toColor, minLag: minLag, maxLag: maxLag, inQuarters: inQuarters }
  if method == "sqrt"
    transform = (v) -> (if v >= 0 then 1 else -1) * Math.sqrt(Math.abs(v))
    tVals = vals.map(transform)
    tMin = d3.min(tVals)
    tMax = d3.max(tVals)
    if tMin >= tMax then tMax = tMin + 1
    colorScale = d3.scaleSequential(d3.interpolateRgbBasis(LAG_RAINBOW)).domain([tMin, tMax])
    toColor = if inQuarters then ((v) -> colorScale(transform(v / DAYS_PER_QUARTER))) else ((v) -> colorScale(transform(v)))
    return { colorScale: toColor, minLag: minLag, maxLag: maxLag, inQuarters: inQuarters }
  if method == "quantile"
    scale = d3.scaleQuantile().domain(vals).range(LAG_RAINBOW)
    toColor = if inQuarters then ((v) -> scale(v / DAYS_PER_QUARTER)) else scale
    return { colorScale: toColor, minLag: minLag, maxLag: maxLag, inQuarters: inQuarters }
  if method == "quarters"
    colorScale = d3.scaleSequential(d3.interpolateRgbBasis(LAG_RAINBOW)).domain([minLag, maxLag])
    toColor = (v) -> colorScale(v / DAYS_PER_QUARTER)
    return { colorScale: toColor, minLag: minLag, maxLag: maxLag, inQuarters: true }
  colorScale = d3.scaleSequential(d3.interpolateRgbBasis(LAG_RAINBOW)).domain([minLag, maxLag])
  return { colorScale: colorScale, minLag: minLag, maxLag: maxLag, inQuarters: false }

# Freshest-component lag heatmap: negative = before list date, positive = after; scale options like quantities; tooltip with component/vendor
drawFreshestLagHeatmap = (data, containerId, title, scaleMethod, gradientId) ->
  data = data or []
  data = [] unless Array.isArray(data)
  fullValid = data.filter((d) -> d.lag != null)
  scaffold = buildHeatmapScaffold({
    containerId: containerId
    requireContainer: true
    data: data
    rankSourceData: fullValid
    extraBottom: 75
    xTickFormat: (d) ->
      if typeof editionDatesLag != "undefined" && editionDatesLag && editionDatesLag[d - 1] then editionDatesLag[d - 1] else d
  })
  return unless scaffold?
  { svg, x, y, width, height } = scaffold
  flexible = lagFlexibleScale(data, scaleMethod)
  colorScale = flexible.colorScale
  minLag = flexible.minLag
  maxLag = flexible.maxLag
  inQuarters = flexible.inQuarters or false
  appendBasicHeatmapCells({
    svg: svg
    data: data
    x: x
    y: y
    containerId: containerId
    colorScale: colorScale
    contourStrokeFn: (d) -> if d.show_before_announce_contour then "#e91e8c" else "none"
    titleFn: (d) ->
      if inQuarters
        q = d.lag / DAYS_PER_QUARTER
        absVal = (if Math.abs(q) >= 10 then Math.round(q) else d3.format(".1f")(Math.abs(q)))
        unit = " кв."
      else
        absVal = Math.abs(d.lag)
        unit = " дн."
      suffix = if d.lag < 0 then " до анонса" else ""
      header = if d.vendor_name and d.component_name then "#{d.vendor_name} #{d.component_name}" else if d.component_name then d.component_name else if d.vendor_name then d.vendor_name else title
      info = "Компонент: #{header}\nРедакция: #{d.edition}, Место: #{d.rank}\nЗначение: #{absVal}#{unit}#{suffix}"
      info += heatmapTooltipSystemLine(d)
      info
  })
  unitStr = if inQuarters then " кв." else " дн."
  fmt = if inQuarters then lagFormatQuarter else lagFormatDay
  leftLabel = if minLag < 0 then fmt(Math.abs(minLag)) + unitStr + " до анонса" else fmt(minLag) + unitStr
  rightLabel = if maxLag < 0 then fmt(Math.abs(maxLag)) + unitStr + " до анонса" else fmt(maxLag) + unitStr
  leftColor = if minLag < 0 then "#2e7d32" else "#c62828"
  appendGradientLegend(svg, {
    width: width
    height: height
    gradientId: gradientId
    colors: LAG_RAINBOW
    leftLabel: leftLabel
    rightLabel: rightLabel
    leftColor: leftColor
    rightColor: "#c62828"
  })

@updateHeatmaps = (scale, dataSets, containerIds, titles, colorScales, downloadIds, downloadFilenames) ->
  for i in [0...dataSets.length]
    data = transformLagData(dataSets[i], scale)
    drawHeatmap(data, containerIds[i], titles[i])
    if downloadIds and downloadIds[i]
      csv = buildLagCsv(data)
      setCsvDownloadLink(downloadIds[i], csv)
      if downloadFilenames and downloadFilenames[i]
        base = downloadFilenames[i].replace(/\.csv$/, "")
        d3.select("#" + downloadIds[i]).attr("download", base + "_" + scale + ".csv")

RAM_STEP_COLORS = ["#f0fff0", "#c8e6c8", "#81c784", "#4caf50", "#388e3c", "#2e7d32", "#1b5e20"]

ramFmt = (x) ->
  if x >= 100 then Math.round(x)
  else if x >= 1 then d3.format(".1f")(x)
  else d3.format(".2f")(x)

componentFmt = (x) ->
  if x >= 1000 then Math.round(x)
  else if x >= 100 then Math.round(x)
  else if x >= 10 then Math.round(x)
  else if x >= 1 then Math.round(x)
  else Math.round(x)

ramFlexibleScale = (data, method) ->
  data = data or []
  data = [] unless Array.isArray(data)
  vals = data.map((d) -> d.lag).filter((v) -> v != null && v != undefined)
  if vals.length == 0
    if method == "gradient" or method == "gradient_sqrt" or method == "gradient_linear"
      scale = d3.scaleLinear().domain([0, 1]).range(RAM_STEP_COLORS).clamp(true)
      return { colorScale: scale, gradient: true, minVal: 0, maxVal: 1 }
    return {
      colorScale: d3.scaleThreshold().domain([1]).range(RAM_STEP_COLORS)
      labels: ["0", "1", "2", "3", "4", "5", "6+"]
    }
  minVal = d3.min(vals)
  maxVal = d3.max(vals)
  if minVal >= maxVal
    maxVal = minVal + 1
  if method == "gradient_linear"
    # Continuous gradient: linear (no transformation)
    domainPts = [minVal]
    for i in [1..5]
      domainPts.push(minVal + (maxVal - minVal) * i / 6)
    domainPts.push(maxVal)
    linearScale = d3.scaleLinear().domain(domainPts).range(RAM_STEP_COLORS).clamp(true)
    scale = (v) -> linearScale(v)
    return { colorScale: scale, gradient: true, minVal: minVal, maxVal: maxVal }
  if method == "gradient"
    # Continuous gradient: more color change at low values (log)
    toTransformed = (v) -> Math.log(1 + Math.max(0, v))
    tMin = toTransformed(minVal)
    tMax = toTransformed(maxVal)
    tMax = tMin + 1 if tMax <= tMin
    domainPts = [tMin]
    for i in [1..5]
      domainPts.push(tMin + (tMax - tMin) * i / 6)
    domainPts.push(tMax)
    linearScale = d3.scaleLinear().domain(domainPts).range(RAM_STEP_COLORS).clamp(true)
    scale = (v) -> linearScale(toTransformed(v))
    return { colorScale: scale, gradient: true, minVal: minVal, maxVal: maxVal }
  if method == "gradient_sqrt"
    # Continuous gradient: more color change at low values (sqrt)
    toTransformed = (v) -> Math.sqrt(Math.max(0, v))
    tMin = toTransformed(minVal)
    tMax = toTransformed(maxVal)
    tMax = tMin + 1 if tMax <= tMin
    domainPts = [tMin]
    for i in [1..5]
      domainPts.push(tMin + (tMax - tMin) * i / 6)
    domainPts.push(tMax)
    linearScale = d3.scaleLinear().domain(domainPts).range(RAM_STEP_COLORS).clamp(true)
    scale = (v) -> linearScale(toTransformed(v))
    return { colorScale: scale, gradient: true, minVal: minVal, maxVal: maxVal }
  if method == "fixed"
    # 7 equal steps from 0 to max (whole interval 0–max)
    step = maxVal / 7
    thresholds = []
    for i in [1..6]
      thresholds.push(step * i)
    labels = [ramFmt(0)]
    for t in thresholds
      labels.push(ramFmt(t))
    scale = d3.scaleThreshold().domain(thresholds).range(RAM_STEP_COLORS)
    return { colorScale: scale, labels: labels }
  if method == "quantile"
    # Equal count per band (each interval has ~same number of points)
    scale = d3.scaleQuantile().domain(vals).range(RAM_STEP_COLORS)
    thresholds = scale.quantiles()
    labels = [ramFmt(minVal)]
    for i in [0...5]
      labels.push(ramFmt(thresholds[i]))
    labels.push(ramFmt(maxVal) + "+")
    return { colorScale: scale, labels: labels }
  if method == "log"
    # Log-spaced over whole interval [min, max]
    minSafe = Math.max(minVal, 0.01)
    maxSafe = Math.max(maxVal, minSafe + 0.01)
    logMin = Math.log(minSafe)
    logMax = Math.log(maxSafe)
    thresholds = []
    for i in [1..6]
      thresholds.push(Math.exp(logMin + (logMax - logMin) * i / 7))
    labels = [ramFmt(minVal)]
    for t in thresholds
      labels.push(ramFmt(t))
    scale = d3.scaleThreshold().domain(thresholds).range(RAM_STEP_COLORS)
    return { colorScale: scale, labels: labels }
  # linear: 7 equal steps over whole interval [min, max]
  step = (maxVal - minVal) / 7
  thresholds = []
  for i in [1..6]
    thresholds.push(minVal + step * i)
  labels = [ramFmt(minVal)]
  for t in thresholds
    labels.push(ramFmt(t))
  scale = d3.scaleThreshold().domain(thresholds).range(RAM_STEP_COLORS)
  return { colorScale: scale, labels: labels }

drawRamLegend = (svg, width, height, spec) ->
  spec = spec or {}
  legendWidth = 320
  legendHeight = 22
  legendX = width / 2 - legendWidth / 2
  legendY = height + 80
  if spec.gradient
    defs = svg.append("defs")
    grad = defs.append("linearGradient")
      .attr("id", spec.gradientId)
      .attr("x1", "0%")
      .attr("x2", "100%")
      .attr("y1", "0%")
      .attr("y2", "0%")
    for i in [0...RAM_STEP_COLORS.length]
      grad.append("stop")
        .attr("offset", (100 * i / (RAM_STEP_COLORS.length - 1)) + "%")
        .attr("stop-color", RAM_STEP_COLORS[i])
    legend = svg.append("g")
      .attr("class", "legend")
      .attr("transform", "translate(#{legendX}, #{legendY})")
    legend.append("rect")
      .attr("width", legendWidth)
      .attr("height", legendHeight)
      .style("fill", "url(##{spec.gradientId})")
      .attr("stroke", "#333")
      .attr("stroke-width", 0.5)
    legend.append("text")
      .attr("x", 0)
      .attr("y", legendHeight + 14)
      .attr("text-anchor", "start")
      .style("font-size", "10px")
      .text(ramFmt(spec.minVal) + " ГБ")
    legend.append("text")
      .attr("x", legendWidth)
      .attr("y", legendHeight + 14)
      .attr("text-anchor", "end")
      .style("font-size", "10px")
      .text(ramFmt(spec.maxVal) + " ГБ")
    return
  labels = spec.labels or spec
  n = RAM_STEP_COLORS.length
  stepWidth = legendWidth / n
  legend = svg.append("g")
    .attr("class", "legend")
    .attr("transform", "translate(#{legendX}, #{legendY})")
  legend.selectAll("rect")
    .data(RAM_STEP_COLORS)
    .enter()
    .append("rect")
    .attr("x", (d, i) -> i * stepWidth)
    .attr("y", 0)
    .attr("width", stepWidth)
    .attr("height", legendHeight)
    .attr("fill", (d) -> d)
    .attr("stroke", "#333")
    .attr("stroke-width", 0.5)
  legend.append("g")
    .selectAll("text")
    .data(labels)
    .enter()
    .append("text")
    .attr("x", (d, i) -> i * stepWidth + stepWidth / 2)
    .attr("y", legendHeight + 14)
    .attr("text-anchor", "middle")
    .style("font-size", "10px")
    .text((d) -> d + " ГБ")

componentFlexibleScale = (data, method) ->
  result = ramFlexibleScale(data, method)
  if result.labels
    result.labels = result.labels.map((label) ->
      labelStr = if typeof label == "string" then label else String(label)
      num = parseFloat(labelStr.replace(/\+$/, ""))
      if isNaN(num) then labelStr else componentFmt(num) + (if labelStr.match(/\+$/) then "+" else "")
    )
  return result

drawComponentLegend = (svg, width, height, spec) ->
  spec = spec or {}
  legendWidth = 320
  legendHeight = 22
  legendX = width / 2 - legendWidth / 2
  legendY = height + 80
  if spec.gradient
    defs = svg.append("defs")
    grad = defs.append("linearGradient")
      .attr("id", spec.gradientId)
      .attr("x1", "0%")
      .attr("x2", "100%")
      .attr("y1", "0%")
      .attr("y2", "0%")
    for i in [0...RAM_STEP_COLORS.length]
      grad.append("stop")
        .attr("offset", (100 * i / (RAM_STEP_COLORS.length - 1)) + "%")
        .attr("stop-color", RAM_STEP_COLORS[i])
    legend = svg.append("g")
      .attr("class", "legend")
      .attr("transform", "translate(#{legendX}, #{legendY})")
    legend.append("rect")
      .attr("width", legendWidth)
      .attr("height", legendHeight)
      .style("fill", "url(##{spec.gradientId})")
      .attr("stroke", "#333")
      .attr("stroke-width", 0.5)
    legend.append("text")
      .attr("x", 0)
      .attr("y", legendHeight + 14)
      .attr("text-anchor", "start")
      .style("font-size", "10px")
      .text(componentFmt(spec.minVal))
    legend.append("text")
      .attr("x", legendWidth)
      .attr("y", legendHeight + 14)
      .attr("text-anchor", "end")
      .style("font-size", "10px")
      .text(componentFmt(spec.maxVal))
    return
  labels = spec.labels or spec
  n = RAM_STEP_COLORS.length
  stepWidth = legendWidth / n
  legend = svg.append("g")
    .attr("class", "legend")
    .attr("transform", "translate(#{legendX}, #{legendY})")
  legend.selectAll("rect")
    .data(RAM_STEP_COLORS)
    .enter()
    .append("rect")
    .attr("x", (d, i) -> i * stepWidth)
    .attr("y", 0)
    .attr("width", stepWidth)
    .attr("height", legendHeight)
    .attr("fill", (d) -> d)
    .attr("stroke", "#333")
    .attr("stroke-width", 0.5)
  legend.append("g")
    .selectAll("text")
    .data(labels)
    .enter()
    .append("text")
    .attr("x", (d, i) -> i * stepWidth + stepWidth / 2)
    .attr("y", legendHeight + 14)
    .attr("text-anchor", "middle")
    .style("font-size", "10px")
    .text((d) -> d)

getComponentHeatmapSize = (editions, rankCount) ->
  margin = { top: 20, right: 20, bottom: 80, left: 60 }
  edCount = (editions and editions.length) or 1
  rankCount = rankCount or 1
  width = Math.max(edCount * HEATMAP_CELL_WIDTH, HEATMAP_MIN_WIDTH)
  height = Math.max(rankCount * HEATMAP_CELL_HEIGHT, HEATMAP_MIN_HEIGHT)
  { width, height, margin }

drawComponentHeatmap = (data, containerId, title, scaleMethod, tooltipUnit = null) ->
  console.log("drawComponentHeatmap called for", containerId, "with", data.length, "data points")
  data = data or []
  data = [] unless Array.isArray(data)
  scaffold = buildHeatmapScaffold({
    containerId: containerId
    requireContainer: true
    data: data
    extraBottom: 75
    sizeResolver: (editions, rankCount) -> getComponentHeatmapSize(editions, rankCount)
    xTickFormat: (d) ->
      if typeof editionDatesComponent != "undefined" && editionDatesComponent && editionDatesComponent[d - 1] then editionDatesComponent[d - 1] else d
  })
  unless scaffold?
    console.error("Container ##{containerId} not found!")
    return
  { svg, x, y, width, height } = scaffold
  method = (scaleMethod and scaleMethod.toString()) or "quantile"
  flexible = componentFlexibleScale(data, method)
  if !flexible or !flexible.colorScale
    console.error("Failed to create scale for ##{containerId}, method: #{method}, data length: #{data.length}")
    return
  colorScale = flexible.colorScale
  legendSpec = if flexible.gradient
    { gradient: true, minVal: flexible.minVal, maxVal: flexible.maxVal, gradientId: "component-grad-" + containerId }
  else
    { labels: flexible.labels }
  appendBasicHeatmapCells({
    svg: svg
    data: data
    x: x
    y: y
    containerId: containerId
    colorScale: colorScale
    titleFn: (d) ->
      valStr = if tooltipUnit then "#{d.lag} #{tooltipUnit}" else "#{Math.round(d.lag)}"
      header = if d.vendor_name and d.component_name then "#{d.vendor_name} #{d.component_name}" else if d.component_name then d.component_name else if d.vendor_name then d.vendor_name else title
      info = "Компонент: #{header}\nРедакция: #{d.edition}, Место: #{d.rank}\nЗначение: #{valStr}"
      info += heatmapTooltipSystemLine(d)
      info
  })
  drawComponentLegend(svg, width, height, legendSpec)

buildComponentCsv = (data) ->
  buildEditionRankGridCsv(data, ((d) -> d.lag), (v) ->
    if v == null or v == undefined then "" else (if typeof v == "number" then Math.round(v).toString() else v)
  )

drawAnnounceToMentionHeatmap = (data, containerId, title, gradientId, unit = "days") ->
  data = data or []
  data = [] unless Array.isArray(data)
  onlyNewEl = document.getElementById("announce-to-mention-only-new")
  if onlyNewEl and onlyNewEl.checked
    data = data.filter((d) -> d.is_new == true)
  scaffold = buildHeatmapScaffold({
    containerId: containerId
    requireContainer: true
    data: data
    extraBottom: 75
    sizeResolver: (editions, rankCount) -> getComponentHeatmapSize(editions, rankCount)
    xTickFormat: (d) ->
      if typeof editionDatesComponent != "undefined" && editionDatesComponent && editionDatesComponent[d - 1] then editionDatesComponent[d - 1] else d
  })
  return unless scaffold?
  { svg, x, y, width, height } = scaffold
  fullValid = data.filter((d) -> d.lag != null)
  inQuarters = (unit == "quarters")
  toVal = if inQuarters then ((d) -> d.lag / DAYS_PER_QUARTER) else ((d) -> d.lag)
  minLag = if fullValid.length then d3.min(fullValid, toVal) else 0
  maxLag = if fullValid.length then d3.max(fullValid, toVal) else 1
  if minLag == null then minLag = 0
  if maxLag == null then maxLag = 1
  if minLag >= maxLag then maxLag = minLag + 1
  rainbowColors = ["#00FF00", "#FFFF00", "#FFA500", "#FF0000", "#0000FF", "#800080"]
  colorScale = d3.scaleSequential(d3.interpolateRgbBasis(rainbowColors)).domain([minLag, maxLag])
  cellColor = if inQuarters then ((d) -> colorScale(d.lag / DAYS_PER_QUARTER)) else ((d) -> colorScale(d.lag))
  appendBasicHeatmapCells({
    svg: svg
    data: data
    x: x
    y: y
    containerId: containerId
    fillFn: (d) -> cellColor(d)
    contourStrokeFn: (d) -> if d.show_before_announce_contour then "#e91e8c" else "none"
    titleFn: (d) ->
      if inQuarters
        q = d.lag / DAYS_PER_QUARTER
        absVal = (if Math.abs(q) >= 10 then Math.round(q) else d3.format(".1f")(Math.abs(q)))
        unitStr = " кв."
      else
        absVal = Math.abs(d.lag)
        unitStr = " дн."
      suffix = if d.lag < 0 then " до анонса" else " после анонса"
      header = if d.vendor_name and d.component_name then "#{d.vendor_name} #{d.component_name}" else if d.component_name then d.component_name else if d.vendor_name then d.vendor_name else title
      info = "Компонент: #{header},\nРедакция: #{d.edition}, Место: #{d.rank},\nЗначение: #{absVal}#{unitStr}#{suffix}"
      info += heatmapTooltipSystemLine(d)
      info
  })
  unitStr = if inQuarters then " кв." else " дн."
  fmt = if inQuarters then lagFormatQuarter else ((d) -> Math.round(d).toString())
  leftLabel = if minLag < 0 then fmt(Math.abs(minLag)) + unitStr + " до анонса" else fmt(minLag) + unitStr + " после анонса"
  rightLabel = if maxLag < 0 then fmt(Math.abs(maxLag)) + unitStr + " до анонса" else fmt(maxLag) + unitStr + " после анонса"
  leftColor = if minLag < 0 then "#2e7d32" else "#c62828"
  appendGradientLegend(svg, {
    width: width
    height: height
    gradientId: gradientId
    colors: rainbowColors
    leftLabel: leftLabel
    rightLabel: rightLabel
    leftColor: leftColor
    rightColor: "#c62828"
  })

drawComponentTable = (data, containerId, title) ->
  data = data or []
  data = [] unless Array.isArray(data)
  d3.select("##{containerId}").selectAll("*").remove()
  
  editions = Array.from(new Set(data.map((d) -> d.edition))).sort((a, b) -> a - b)
  ranks = Array.from({ length: getMaxRank() }, (_, i) -> i + 1)
  
  lookup = {}
  data.forEach((d) ->
    if d.lag != null and d.lag != undefined
      lookup["#{d.edition}-#{d.rank}"] = d.lag
  )
  
  editionLabels = editions.map((ed) ->
    if typeof editionDatesComponent != "undefined" && editionDatesComponent && editionDatesComponent[ed - 1]
      editionDatesComponent[ed - 1]
    else
      ed.toString()
  )
  
  table = d3.select("##{containerId}").append("table")
    .style("border-collapse", "collapse")
    .style("font-size", "12px")
    .style("margin", "10px 0")
  
  thead = table.append("thead")
  headerRow = thead.append("tr")
  headerRow.append("th")
    .text("Ранг")
    .style("border", "1px solid #ccc")
    .style("padding", "5px")
    .style("background-color", "#f0f0f0")
    .style("position", "sticky")
    .style("left", "0")
    .style("z-index", "10")
  
  headerRow.selectAll("th.edition-header")
    .data(editionLabels)
    .enter()
    .append("th")
    .attr("class", "edition-header")
    .text((d) -> d)
    .style("border", "1px solid #ccc")
    .style("padding", "5px")
    .style("background-color", "#f0f0f0")
    .style("min-width", "50px")
    .style("text-align", "center")
  
  tbody = table.append("tbody")
  rows = tbody.selectAll("tr")
    .data(ranks)
    .enter()
    .append("tr")
  
  rows.append("td")
    .text((rank) -> rank)
    .style("border", "1px solid #ccc")
    .style("padding", "5px")
    .style("background-color", "#f5f5f5")
    .style("font-weight", "bold")
    .style("text-align", "right")
  
  rows.selectAll("td.data-cell")
    .data((rank) -> editions.map((ed) -> { edition: ed, rank: rank }))
    .enter()
    .append("td")
    .attr("class", "data-cell")
    .text((d) ->
      v = lookup["#{d.edition}-#{d.rank}"]
      if v == null or v == undefined then "" else (if typeof v == "number" then Math.round(v).toString() else v.toString())
    )
    .style("border", "1px solid #ccc")
    .style("padding", "5px")
    .style("text-align", "right")
    .style("background-color", (d) ->
      v = lookup["#{d.edition}-#{d.rank}"]
      if v == null or v == undefined then "#fff"
      else if v == 0 then "#f9f9f9"
      else "#e8f5e9"
    )

@updateComponentHeatmaps = (dataSets, containerIds, titles, downloadIds, downloadFilenames, scaleMethod) ->
  dataSets = dataSets or []
  console.log("updateComponentHeatmaps called with", dataSets.length, "datasets, scaleMethod:", scaleMethod)
  for i in [0...dataSets.length]
    data = dataSets[i]
    data = [] if !data or !Array.isArray(data)
    console.log("Drawing heatmap", i, "container:", containerIds[i], "data points:", data.length)
    drawComponentHeatmap(data, containerIds[i], titles[i], scaleMethod)
    if downloadIds and downloadIds[i]
      csv = buildComponentCsv(data)
      setCsvDownloadLink(downloadIds[i], csv)
      if downloadFilenames and downloadFilenames[i]
        d3.select("#" + downloadIds[i]).attr("download", downloadFilenames[i])

drawRamHeatmap = (data, containerId, title, scaleMethod) ->
  data = data or []
  data = [] unless Array.isArray(data)
  scaffold = buildHeatmapScaffold({
    containerId: containerId
    data: data
    extraBottom: 75
    xTickFormat: (d) ->
      if typeof editionDatesRam != "undefined" && editionDatesRam && editionDatesRam[d - 1] then editionDatesRam[d - 1] else d
  })
  return unless scaffold?
  { svg, x, y, width, height } = scaffold
  method = (scaleMethod and scaleMethod.toString()) or "quantile"
  flexible = ramFlexibleScale(data, method)
  colorScale = flexible.colorScale
  legendSpec = if flexible.gradient
    { gradient: true, minVal: flexible.minVal, maxVal: flexible.maxVal, gradientId: "ram-grad-" + containerId }
  else
    { labels: flexible.labels }
  appendBasicHeatmapCells({
    svg: svg
    data: data
    x: x
    y: y
    containerId: containerId
    fillFn: (d) -> if d.has_gpu then "#f0f0f0" else colorScale(d.lag)
    afterCells: (cells) ->
      cells.filter((d) -> d.has_gpu)
        .append("ellipse")
        .attr("cx", (d) -> x(d.edition) + x.bandwidth() / 2)
        .attr("cy", (d) -> y(d.rank) + y.bandwidth() / 2)
        .attr("rx", (d) -> x.bandwidth() * 0.4)
        .attr("ry", (d) -> y.bandwidth() * 0.4)
        .attr("fill", (d) -> colorScale(d.lag))
        .attr("stroke", "#000")
        .attr("stroke-width", 0.5)
    titleFn: (d) ->
      info = "#{title}\nРедакция: #{d.edition}, Место: #{d.rank}\nЗначение: #{d3.format(".2f")(d.lag)} ГБ"
      if d.has_gpu
        info += "\nГибридная система (с GPU)"
      info += heatmapTooltipSystemLine(d)
      info
  })
  drawRamLegend(svg, width, height, legendSpec)

buildRamCsv = (data) ->
  buildEditionRankGridCsv(data, ((d) -> d.lag), (v) ->
    if v == null or v == undefined then "" else (if typeof v == "number" then v.toFixed(2) else v)
  )

@updateRamHeatmaps = (dataSets, containerIds, titles, downloadIds, downloadFilenames, scaleMethod) ->
  dataSets = dataSets or []
  for i in [0...dataSets.length]
    data = dataSets[i]
    data = [] if !data or !Array.isArray(data)
    drawRamHeatmap(data, containerIds[i], titles[i], scaleMethod)
    if downloadIds and downloadIds[i]
      csv = buildRamCsv(data)
      setCsvDownloadLink(downloadIds[i], csv)
      if downloadFilenames and downloadFilenames[i]
        d3.select("#" + downloadIds[i]).attr("download", downloadFilenames[i])

runStatsWhenReady = (fn) ->
  if document.readyState == "loading"
    document.addEventListener("DOMContentLoaded", fn)
  else
    fn()

resolveGraphChoice = (selectorId, graphConfigs, fallbackKey) ->
  selector = document.getElementById(selectorId)
  selectedKey = selector?.value or fallbackKey
  unless graphConfigs[selectedKey]?
    selectedKey = fallbackKey
  cfg = graphConfigs[selectedKey]
  unless cfg?
    keys = Object.keys(graphConfigs or {})
    selectedKey = keys[0]
    cfg = graphConfigs[selectedKey]
  if selector and selectedKey? and selector.value != selectedKey
    selector.value = selectedKey
  { key: selectedKey, config: cfg, selector: selector }

applyGraphVisibility = (graphConfigs, activeKey) ->
  for key, cfg of (graphConfigs or {})
    next unless cfg?.wrapperId
    wrapper = document.getElementById(cfg.wrapperId)
    continue unless wrapper
    wrapper.style.display = if key == activeKey then "" else "none"

valueOr = (id, fallback) ->
  (document.getElementById(id) or {}).value or fallback

bindChangeByIds = (ids, handler) ->
  (ids or []).forEach((id) ->
    el = document.getElementById(id)
    if el then el.addEventListener("change", handler)
  )

setCsvDownloadLink = (linkId, csv, downloadName = null) ->
  return unless linkId
  link = d3.select("#" + linkId)
  return if link.empty()
  link.attr("href", "data:text/csv;charset=utf-8," + encodeURIComponent(csv))
  if downloadName?
    link.attr("download", downloadName)

parseSelectInt = (id, fallback) ->
  v = parseInt((document.getElementById(id) or {}).value, 10)
  if isNaN(v) then fallback else v

readEditionRankRangeFromDom = (editionStartId, editionEndId, rankStartId, rankEndId, maxEdition) ->
  es = parseSelectInt(editionStartId, 1)
  ee = parseSelectInt(editionEndId, maxEdition)
  rs = parseSelectInt(rankStartId, 1)
  re = parseSelectInt(rankEndId, getMaxRank())
  if es > ee then [es, ee] = [ee, es]
  if rs > re then [rs, re] = [re, rs]
  {
    editionStart: Math.max(1, es)
    editionEnd: Math.max(1, Math.min(maxEdition, ee))
    rankStart: Math.max(1, rs)
    rankEnd: Math.min(getMaxRank(), re)
  }

filterByEditionAndRankRange = (data, ranges) ->
  (data or []).filter((d) ->
    ed = d.edition
    rk = d.rank
    ed? and rk? and ed >= ranges.editionStart and ed <= ranges.editionEnd and rk >= ranges.rankStart and rk <= ranges.rankEnd
  )

syncRangePair = (startId, endId, keep = "start_lte_end") ->
  startSel = document.getElementById(startId)
  endSel = document.getElementById(endId)
  return unless startSel and endSel
  if keep == "start_lte_end"
    startIdx = parseInt(startSel.selectedIndex)
    for i in [0...endSel.options.length]
      endSel.options[i].hidden = i < startIdx
    if endSel.selectedIndex < startIdx
      endSel.selectedIndex = startIdx
    endIdx = parseInt(endSel.selectedIndex)
    for i in [0...startSel.options.length]
      startSel.options[i].hidden = i > endIdx
    if startSel.selectedIndex > endIdx
      startSel.selectedIndex = endIdx
  else
    for i in [0...startSel.options.length]
      startSel.options[i].hidden = false
    startIdx = parseInt(startSel.selectedIndex)
    for i in [0...endSel.options.length]
      endSel.options[i].hidden = i > startIdx
    if endSel.selectedIndex > startIdx
      endSel.selectedIndex = startIdx

sliceChartSeriesByEditionRange = (chartData, edFrom, edTo) ->
  return [] unless chartData and chartData.length > 0
  chartData.map((s) ->
    arr = (s.data or []).slice(edFrom - 1, edTo)
    { name: s.name, color: s.color, data: arr.map((p) -> [p[0], p[1]]) }
  )

escapeCsvField = (v) ->
  s = String(v)
  if /[,"\n\r]/.test(s) then '"' + s.replace(/"/g, '""') + '"' else s

runStatsWhenReady ->
  scaleSelector = document.getElementById("scale-selector")
  if scaleSelector and typeof cpuDataLinear != "undefined"
    dataSets = [cpuDataLinear, gpuDataLinear, combinedDataLinear]
    containerIds = ["cpu_heatmap", "gpu_heatmap", "combined_heatmap"]
    downloadIds = ["download_cpu_lag", "download_gpu_lag", "download_combined_lag"]
    downloadFilenames = ["CPU_lag.csv", "GPU_lag.csv", "Combined_lag.csv"]
    titles = ["CPU Задержка", "GPU Задержка", "Общая задержка min(CPU, GPU)"]
    gradientIds = ["lag-legend-cpu", "lag-legend-gpu", "lag-legend-combined"]
    lagGraphConfigs =
      cpu: { index: 0, wrapperId: "lag-graph-cpu" }
      gpu: { index: 1, wrapperId: "lag-graph-gpu" }
      combined: { index: 2, wrapperId: "lag-graph-combined" }
    getFreshestLagScale = () ->
      valueOr("scale-selector", "linear")

    updateLagHeatmaps = () ->
      syncRangePair("lag-edition-start", "lag-edition-end", "start_lte_end")
      syncRangePair("lag-rank-start", "lag-rank-end", "start_lte_end")
      scaleMethod = getFreshestLagScale()
      inQuarters = (scaleMethod == "quarters")
      # Текущие значения диапазонов
      edStartSel = document.getElementById("lag-edition-start")
      edEndSel   = document.getElementById("lag-edition-end")
      rkStartSel = document.getElementById("lag-rank-start")
      rkEndSel   = document.getElementById("lag-rank-end")
      edFrom = parseInt(edStartSel?.value) or 1
      edTo   = parseInt(edEndSel?.value)   or (editionDatesLag?.length or edFrom)
      rkFrom = parseInt(rkStartSel?.value) or 1
      rkTo   = parseInt(rkEndSel?.value)   or getMaxRank()
      selected = resolveGraphChoice("lag-graph-selector", lagGraphConfigs, "cpu")
      applyGraphVisibility(lagGraphConfigs, selected.key)
      i = selected.config?.index
      return unless i?
      fullData = dataSets[i] or []
      data = fullData.filter((d) ->
        ed = d.edition
        rk = d.rank
        ed? and rk? and ed >= edFrom and ed <= edTo and rk >= rkFrom and rk <= rkTo
      )
      drawFreshestLagHeatmap(data, containerIds[i], titles[i], scaleMethod, gradientIds[i])
      if downloadIds and downloadIds[i]
        csv = buildLagCsv(data, inQuarters)
        setCsvDownloadLink(downloadIds[i], csv)
        if downloadFilenames and downloadFilenames[i]
          base = downloadFilenames[i].replace(/\.csv$/, "")
          ext = if inQuarters then "_quarters.csv" else ".csv"
          d3.select("#" + downloadIds[i]).attr("download", base + ext)

    updateLagHeatmaps()
    scaleSelector.addEventListener("change", updateLagHeatmaps)
    lagStartEd = document.getElementById("lag-edition-start")
    lagEndEd = document.getElementById("lag-edition-end")
    lagStartRank = document.getElementById("lag-rank-start")
    lagEndRank = document.getElementById("lag-rank-end")
    if lagStartEd then lagStartEd.addEventListener("change", updateLagHeatmaps)
    if lagEndEd then lagEndEd.addEventListener("change", updateLagHeatmaps)
    if lagStartRank then lagStartRank.addEventListener("change", updateLagHeatmaps)
    if lagEndRank then lagEndRank.addEventListener("change", updateLagHeatmaps)
    lagGraphSelector = document.getElementById("lag-graph-selector")
    if lagGraphSelector then lagGraphSelector.addEventListener("change", updateLagHeatmaps)

  if typeof ramPerCoreData != "undefined"
    ramDataSets = [
      ramPerCoreData || [],
      (if typeof ramPerCpuData != "undefined" then ramPerCpuData else []),
      (if typeof ramPerNodeData != "undefined" then ramPerNodeData else [])
    ]
    ramContainerIds = ["ram_per_core_heatmap", "ram_per_cpu_heatmap", "ram_per_node_heatmap"]
    ramDownloadIds = ["download_ram_per_core", "download_ram_per_cpu", "download_ram_per_node"]
    ramDownloadFilenames = ["RAM_per_core.csv", "RAM_per_cpu.csv", "RAM_per_node.csv"]
    ramTitles = ["RAM на ядро", "RAM на CPU", "RAM на узел"]
    ramGraphConfigs =
      core: { index: 0, wrapperId: "ram-graph-core" }
      cpu: { index: 1, wrapperId: "ram-graph-cpu" }
      node: { index: 2, wrapperId: "ram-graph-node" }
    getRamScale = () -> valueOr("scale-selector-ram", "quantile")
    getRamShowHybrid = () ->
      el = document.getElementById("ram-show-hybrid")
      el and el.checked
    getRamRanges = () ->
      maxEdition = (editionDatesRam || []).length or 1
      readEditionRankRangeFromDom("ram-edition-start", "ram-edition-end", "ram-rank-start", "ram-rank-end", maxEdition)
    updateRamAll = () ->
      showHybrid = getRamShowHybrid()
      ranges = getRamRanges()
      baseSets = if showHybrid
        ramDataSets
      else
        ramDataSets.map((data) -> (data or []).filter((d) -> !d.has_gpu))
      filtered = baseSets.map((data) -> filterByEditionAndRankRange(data, ranges))
      selected = resolveGraphChoice("ram-graph-selector", ramGraphConfigs, "node")
      applyGraphVisibility(ramGraphConfigs, selected.key)
      i = selected.config?.index
      return unless i?
      updateRamHeatmaps([filtered[i]], [ramContainerIds[i]], [ramTitles[i]], [ramDownloadIds[i]], [ramDownloadFilenames[i]], getRamScale())
    updateRamAll()
    ramScaleEl = document.getElementById("scale-selector-ram")
    if ramScaleEl
      ramScaleEl.addEventListener("change", updateRamAll)
    ramShowHybridEl = document.getElementById("ram-show-hybrid")
    if ramShowHybridEl
      ramShowHybridEl.addEventListener("change", updateRamAll)
    bindChangeByIds(["ram-edition-start","ram-edition-end","ram-rank-start","ram-rank-end"], updateRamAll)
    ramGraphEl = document.getElementById("ram-graph-selector")
    if ramGraphEl
      ramGraphEl.addEventListener("change", updateRamAll)

  if typeof cpuTotalData != "undefined"
    getComponentMetric = () -> valueOr("metric-selector-component", "total")
    getComponentScale = () -> valueOr("scale-selector-component", "quantile")
    getFreshestIncludeGpu = () ->
      el = document.getElementById("freshest-include-gpu")
      el and el.checked
    getComponentRanges = () ->
      maxEdition = (editionDatesComponent || []).length or 1
      readEditionRankRangeFromDom("component-edition-start", "component-edition-end", "component-rank-start", "component-rank-end", maxEdition)
    componentGraphConfigs =
      cpu: { index: 0, wrapperId: "component-graph-cpu" }
      gpu: { index: 1, wrapperId: "component-graph-gpu" }
      freshest: { index: 2, wrapperId: "component-graph-freshest" }
      cores: { index: 3, wrapperId: "component-graph-cores" }
      gpu_cores: { index: 4, wrapperId: "component-graph-gpu-cores" }
      gpu_microcores: { index: 5, wrapperId: "component-graph-gpu-microcores" }

    updateComponentAll = () ->
      metric = getComponentMetric()
      scaleMethod = getComponentScale()
      includeGpu = getFreshestIncludeGpu()
      ranges = getComponentRanges()
      freshestTotal = if includeGpu then (freshestTotalData || []) else (freshestTotalDataCpuOnly || [])
      freshestPerNode = if includeGpu then (freshestPerNodeData || []) else (freshestPerNodeDataCpuOnly || [])
      if metric == "total"
        baseSets = [
          cpuTotalData || [],
          gpuTotalData || [],
          freshestTotal,
          coresTotalData || [],
          gpuCoresTotalData || [],
          gpuMicrocoresOnlyTotalData || []
        ]
        componentTitles = ["Количество CPU: всего", "Количество GPU: всего", "Количество самых свежих компонент: всего", "Количество CPU ядер: всего", "Количество GPU ядер: всего", "Количество GPU микроядер: всего"]
        componentDownloadFilenames = ["CPU_total.csv", "GPU_total.csv", "Freshest_total.csv", "Cores_total.csv", "GPU_cores_total.csv", "GPU_microcores_total.csv"]
      else
        baseSets = [
          cpuPerNodeData || [],
          gpuPerNodeData || [],
          freshestPerNode,
          coresPerNodeData || [],
          gpuCoresPerNodeData || [],
          gpuMicrocoresOnlyPerNodeData || []
        ]
        componentTitles = ["Количество CPU: на узел", "Количество GPU: на узел", "Количество самых свежих компонент: на узел", "Количество CPU ядер: на узел", "Количество GPU ядер: на узел", "Количество GPU микроядер: на узел"]
        componentDownloadFilenames = ["CPU_per_node.csv", "GPU_per_node.csv", "Freshest_per_node.csv", "Cores_per_node.csv", "GPU_cores_per_node.csv", "GPU_microcores_per_node.csv"]
      componentDataSets = baseSets.map((data) -> filterByEditionAndRankRange(data, ranges))
      componentContainerIds = ["cpu_component_heatmap", "gpu_component_heatmap", "freshest_component_heatmap", "cores_component_heatmap", "gpu_cores_component_heatmap", "gpu_microcores_only_component_heatmap"]
      componentDownloadIds = ["download_cpu_component", "download_gpu_component", "download_freshest_component", "download_cores_component", "download_gpu_cores_component", "download_gpu_microcores_only_component"]
      selected = resolveGraphChoice("component-graph-selector", componentGraphConfigs, "cpu")
      applyGraphVisibility(componentGraphConfigs, selected.key)
      i = selected.config?.index
      return unless i?
      updateComponentHeatmaps([componentDataSets[i]], [componentContainerIds[i]], [componentTitles[i]], [componentDownloadIds[i]], [componentDownloadFilenames[i]], scaleMethod)
    updateComponentAll()
    componentMetricEl = document.getElementById("metric-selector-component")
    if componentMetricEl
      componentMetricEl.addEventListener("change", updateComponentAll)
    componentScaleEl = document.getElementById("scale-selector-component")
    if componentScaleEl
      componentScaleEl.addEventListener("change", updateComponentAll)
    freshestIncludeGpuEl = document.getElementById("freshest-include-gpu")
    if freshestIncludeGpuEl
      freshestIncludeGpuEl.addEventListener("change", updateComponentAll)
    bindChangeByIds(["component-edition-start","component-edition-end","component-rank-start","component-rank-end"], updateComponentAll)
    componentGraphEl = document.getElementById("component-graph-selector")
    if componentGraphEl
      componentGraphEl.addEventListener("change", updateComponentAll)

  # ---------- fr_comp_stats: heatmaps — same pattern as freshest_components_lag (option constraining + filter + redraw) ----------
  if typeof freshestCpuQuantityData != "undefined"
    freshestHeatmapGraphConfigs =
      cpu_quantity: { wrapperId: "freshest-heatmap-graph-cpu-quantity" }
      gpu_quantity: { wrapperId: "freshest-heatmap-graph-gpu-quantity" }
      announce_cpu: { wrapperId: "freshest-heatmap-graph-announce-cpu" }
      announce_gpu: { wrapperId: "freshest-heatmap-graph-announce-gpu" }
    getFreshestQuantityScale = () -> valueOr("scale-selector-freshest-quantity", "quantile")
    updateFreshestQuantityHeatmaps = () ->
      syncRangePair("freshest-heatmap-edition-start", "freshest-heatmap-edition-end", "start_lte_end")
      syncRangePair("freshest-heatmap-rank-start", "freshest-heatmap-rank-end", "start_lte_end")
      container = document.getElementById("freshest_cpu_quantity_heatmap")
      return unless container
      edStartSel = document.getElementById("freshest-heatmap-edition-start")
      edEndSel = document.getElementById("freshest-heatmap-edition-end")
      rkStartSel = document.getElementById("freshest-heatmap-rank-start")
      rkEndSel = document.getElementById("freshest-heatmap-rank-end")
      edFrom = parseInt(edStartSel?.value) or 1
      edTo = parseInt(edEndSel?.value) or (editionDatesFreshestQuantity?.length or edFrom)
      rkFrom = parseInt(rkStartSel?.value) or 1
      rkTo = parseInt(rkEndSel?.value) or getMaxRank()
      ranges = { editionStart: edFrom, editionEnd: edTo, rankStart: rkFrom, rankEnd: rkTo }
      dataCpu = filterByEditionAndRankRange(freshestCpuQuantityData or [], ranges)
      dataGpu = filterByEditionAndRankRange(freshestGpuQuantityData or [], ranges)
      selected = resolveGraphChoice("freshest-heatmap-graph-selector", freshestHeatmapGraphConfigs, "cpu_quantity")
      applyGraphVisibility(freshestHeatmapGraphConfigs, selected.key)
      announceControls = document.getElementById("freshest-announce-controls")
      if announceControls
        showAnnounceControls = (selected.key == "announce_cpu" or selected.key == "announce_gpu")
        announceControls.style.display = if showAnnounceControls then "" else "none"
      scaleMethod = getFreshestQuantityScale()
      if selected.key == "cpu_quantity"
        drawComponentHeatmap(dataCpu, "freshest_cpu_quantity_heatmap", "Самые свежие CPU: количество", scaleMethod)
        if document.getElementById("download_freshest_cpu_quantity")
          csvCpu = buildComponentCsv(dataCpu)
          setCsvDownloadLink("download_freshest_cpu_quantity", csvCpu)
      else if selected.key == "gpu_quantity"
        drawComponentHeatmap(dataGpu, "freshest_gpu_quantity_heatmap", "Самые свежие GPU: количество", scaleMethod)
        if document.getElementById("download_freshest_gpu_quantity")
          csvGpu = buildComponentCsv(dataGpu)
          setCsvDownloadLink("download_freshest_gpu_quantity", csvGpu)
      if typeof announceToMentionCpuData != "undefined"
        dataAnnounceCpu = filterByEditionAndRankRange(announceToMentionCpuData or [], ranges)
        dataAnnounceGpu = filterByEditionAndRankRange(announceToMentionGpuData or [], ranges)
        announceUnit = valueOr("announce-to-mention-unit", "days")
        if selected.key == "announce_cpu"
          drawAnnounceToMentionHeatmap(dataAnnounceCpu, "announce_to_mention_cpu_heatmap", "CPU: разница между анонсом и первым появлением в рейтинге", "announce-to-mention-legend-cpu", announceUnit)
        else if selected.key == "announce_gpu"
          drawAnnounceToMentionHeatmap(dataAnnounceGpu, "announce_to_mention_gpu_heatmap", "GPU: разница между анонсом и первым появлением в рейтинге", "announce-to-mention-legend-gpu", announceUnit)
        inQuarters = (announceUnit == "quarters")
        if selected.key == "announce_cpu" and document.getElementById("download_announce_to_mention_cpu")
          csvCpu = if inQuarters then buildLagCsv(dataAnnounceCpu, true) else buildComponentCsv(dataAnnounceCpu)
          setCsvDownloadLink("download_announce_to_mention_cpu", csvCpu, if inQuarters then "CPU_announce_to_mention_quarters.csv" else "CPU_announce_to_mention_days.csv")
        if selected.key == "announce_gpu" and document.getElementById("download_announce_to_mention_gpu")
          csvGpu = if inQuarters then buildLagCsv(dataAnnounceGpu, true) else buildComponentCsv(dataAnnounceGpu)
          setCsvDownloadLink("download_announce_to_mention_gpu", csvGpu, if inQuarters then "GPU_announce_to_mention_quarters.csv" else "GPU_announce_to_mention_days.csv")
    updateFreshestQuantityHeatmaps()
    scaleFreshestEl = document.getElementById("scale-selector-freshest-quantity")
    if scaleFreshestEl
      scaleFreshestEl.addEventListener("change", updateFreshestQuantityHeatmaps)
    announceOnlyNewEl = document.getElementById("announce-to-mention-only-new")
    if announceOnlyNewEl
      announceOnlyNewEl.addEventListener("change", updateFreshestQuantityHeatmaps)
    announceUnitEl = document.getElementById("announce-to-mention-unit")
    if announceUnitEl
      announceUnitEl.addEventListener("change", updateFreshestQuantityHeatmaps)
    freshestHeatmapSelIds = ["freshest-heatmap-edition-start", "freshest-heatmap-edition-end", "freshest-heatmap-rank-start", "freshest-heatmap-rank-end"]
    bindChangeByIds(freshestHeatmapSelIds, updateFreshestQuantityHeatmaps)
    freshestHeatmapGraphEl = document.getElementById("freshest-heatmap-graph-selector")
    if freshestHeatmapGraphEl
      freshestHeatmapGraphEl.addEventListener("change", updateFreshestQuantityHeatmaps)

  # fr_comp_stats: bar charts — separate edition dropdowns (not heatmaps), filter + scroll + sticky Y
  initFreshestBarCharts = ->
    fqStartSel = document.getElementById("freshest-charts-edition-start")
    fqEndSel   = document.getElementById("freshest-charts-edition-end")
    fqChartEl  = document.getElementById("chart_freshest_quantity_systems")
    return unless fqStartSel and fqEndSel and fqChartEl and typeof window.editionDatesFreshestQuantity != "undefined"
    fqCharts =
      systems: { id: "chart_freshest_quantity_systems", wrapperId: "freshest-bar-graph-systems", dataKey: "chartDataFreshestQuantity", title: "Количество систем с новыми компонентами по редакциям", xLabel: "Дата (ММ.ГГ)", yLabel: "Количество систем" }
      models: { id: "chart_freshest_quantity_models", wrapperId: "freshest-bar-graph-models", dataKey: "chartDataFreshestQuantityModels", title: "Количество новых моделей компонент по редакциям", xLabel: "Дата (ММ.ГГ)", yLabel: "Количество моделей" }
      components: { id: "chart_freshest_quantity_components", wrapperId: "freshest-bar-graph-components", dataKey: "chartDataFreshestQuantityComponents", title: "Количество новых компонент по редакциям", xLabel: "Дата (ММ.ГГ)", yLabel: "Количество компонент" }
      pct_all: { id: "chart_freshest_quantity_pct_all", wrapperId: "freshest-bar-graph-pct-all", dataKey: "chartDataFreshestQuantityPctAll", title: "Доля новых компонент (от компонент всех систем), %", xLabel: "Дата (ММ.ГГ)", yLabel: "% от всех компонент" }
      pct_new_systems: { id: "chart_freshest_quantity_pct_new_systems", wrapperId: "freshest-bar-graph-pct-new-systems", dataKey: "chartDataFreshestQuantityPctNewSystems", title: "Доля новых компонент (от компонент систем с новыми), %", xLabel: "Дата (ММ.ГГ)", yLabel: "% от всех компонент" }
      rpeak_pct: { id: "chart_freshest_quantity_rpeak_pct", wrapperId: "freshest-bar-graph-rpeak-pct", dataKey: "chartDataFreshestQuantityRpeakPct", title: "Процент Rpeak (от общего) систем с новыми компонентами", xLabel: "Дата (ММ.ГГ)", yLabel: "% Rpeak" }
      rmax_pct: { id: "chart_freshest_quantity_rmax_pct", wrapperId: "freshest-bar-graph-rmax-pct", dataKey: "chartDataFreshestQuantityRmaxPct", title: "Процент Rmax (от общего) систем с новыми компонентами", xLabel: "Дата (ММ.ГГ)", yLabel: "% Rmax" }
    fqGraphSelector = document.getElementById("freshest-bar-graph-selector")
    availableFqCharts = {}
    for key, cfg of fqCharts
      chartEl = document.getElementById(cfg.id)
      wrapperEl = document.getElementById(cfg.wrapperId)
      availableFqCharts[key] = !!(chartEl and wrapperEl)
    getAvailableFqKey = () ->
      keys = Object.keys(fqCharts)
      for i in [0...keys.length]
        key = keys[i]
        return key if availableFqCharts[key]
      "systems"
    updateFqGraphOptions = () ->
      return unless fqGraphSelector
      selected = fqGraphSelector.value
      hasSelected = false
      for i in [0...fqGraphSelector.options.length]
        opt = fqGraphSelector.options[i]
        isAvailable = !!availableFqCharts[opt.value]
        opt.hidden = !isAvailable
        opt.disabled = !isAvailable
        hasSelected = true if isAvailable and opt.value == selected
      unless hasSelected
        fqGraphSelector.value = getAvailableFqKey()
    # Second dropdown (start) = main (all options). First dropdown (end) = dependent, limited by start.
    updateFqStartOptions = () ->
      return unless fqStartSel
      for i in [0...fqStartSel.options.length]
        fqStartSel.options[i].hidden = false
    updateFqEndOptions = () ->
      return unless fqStartSel and fqEndSel
      startIdx = parseInt(fqStartSel.selectedIndex)
      for i in [0...fqEndSel.options.length]
        fqEndSel.options[i].hidden = i > startIdx
      if fqEndSel.selectedIndex > startIdx
        fqEndSel.selectedIndex = startIdx
    sliceFqChartData = sliceChartSeriesByEditionRange
    updateFqBarCharts = () ->
      updateFqGraphOptions()
      updateFqStartOptions()
      updateFqEndOptions()
      startVal = parseInt(fqStartSel?.value, 10) or 1
      maxEd = (window.editionDatesFreshestQuantity or []).length or 1
      endVal = parseInt(fqEndSel?.value, 10) or maxEd
      startVal = Math.max(1, Math.min(startVal, maxEd))
      endVal = Math.max(1, Math.min(endVal, maxEd))
      edFrom = Math.min(startVal, endVal)
      edTo = Math.max(startVal, endVal)
      numPoints = Math.max(0, edTo - edFrom + 1)
      minChartWidth = Math.max(1000, numPoints * 40)
      selected = resolveGraphChoice("freshest-bar-graph-selector", fqCharts, getAvailableFqKey())
      applyGraphVisibility(fqCharts, selected.key)
      cfg = selected.config
      return unless cfg?
      el = document.getElementById(cfg.id)
      return unless el
      el.style.minWidth = minChartWidth + "px"
      data = window[cfg.dataKey]
      return unless data and data.length and data[0].data
      filtered = sliceFqChartData(data, edFrom, edTo)
      if filtered.length > 0 and filtered[0].data and filtered[0].data.length > 0
        draw_new_vs_upgraded_new(filtered, cfg.id, cfg.title, cfg.xLabel, cfg.yLabel)
    updateFqBarCharts()
    fqStartSel.addEventListener("change", updateFqBarCharts)
    fqEndSel.addEventListener("change", updateFqBarCharts)
    if fqGraphSelector
      fqGraphSelector.addEventListener("change", updateFqBarCharts)

  initFreshestBarCharts()

  initAreaAndListUpgStats = ->
    lagByEdition = window.componentsByAreaLagByEdition
    qtyByEdition = window.componentsByAreaNewQtyByEdition
    systemsWithNewByEdition = window.componentsByAreaSystemsWithNewByEdition
    newUpgradedByEdition = window.componentsByAreaNewUpgradedByEdition
    return unless Array.isArray(lagByEdition) and Array.isArray(qtyByEdition) and lagByEdition.length > 0
    prevBtn = document.getElementById("components-by-area-prev")
    nextBtn = document.getElementById("components-by-area-next")
    labelEl = document.getElementById("components-by-area-edition-label")
    metricSel = document.getElementById("components-by-area-metric")
    lagUnitSel = document.getElementById("components-by-area-lag-unit")
    lagUnitLabel = document.getElementById("components-by-area-lag-unit-label")
    lagUnitWrap = document.getElementById("components-by-area-lag-unit-wrap")
    tableHead = document.getElementById("area_upg_table_head")
    tableBody = document.getElementById("area_upg_table_body")
    csvLink = document.getElementById("download_area_upg_csv")
    tableBtnLag = document.getElementById("cba-table-btn-lag")
    tableBtnNewComponents = document.getElementById("cba-table-btn-new-components")
    tableBtnSystemsNewComp = document.getElementById("cba-table-btn-systems-new-comp")
    tableBtnNewSystems = document.getElementById("cba-table-btn-new-systems")
    tableBtnUpgradedSystems = document.getElementById("cba-table-btn-upgraded-systems")
    tableBtnShare = document.getElementById("cba-table-btn-share")
    editionMeta = window.componentsByAreaEditionMeta or {}
    return unless prevBtn and nextBtn and labelEl

    idx = lagByEdition.length - 1
    maxIdx = lagByEdition.length - 1
    tableMetric = "lag_avg"
    tableShowShare = false
    metricSupportsShare = (m) -> ["systems_with_new", "new_systems", "upgraded_systems"].indexOf(m) >= 0
    lagValueWithUnit = (days, unit) ->
      raw = +(days or 0)
      return raw unless unit == "quarters"
      Math.round((raw / 91.3125) * 100) / 100
    formatPct = (v) ->
      return "" unless v?
      s = ((Math.round((+v) * 100) / 100).toFixed(2))
      s.replace(/\.00$/, "").replace(/(\.\d)0$/, "$1")
    preferredAreas = ["Наука и образование", "Исследования", "Промышленность", "IT Services", "Геофизика", "Производитель", "Финансы", "Seismic Processing", "Не указано/Прочие"]
    collectAreas = () ->
      seen = {}
      all = []
      [lagByEdition, qtyByEdition, systemsWithNewByEdition, newUpgradedByEdition].forEach((arr) ->
        (arr or []).forEach((ed) ->
          (ed.data or []).forEach((p) ->
            a = p.area
            if a? and !seen[a]
              seen[a] = true
              all.push(a)
          )
        )
      )
      ordered = []
      preferredAreas.forEach((a) -> ordered.push(a) if seen[a])
      all.forEach((a) -> ordered.push(a) unless ordered.indexOf(a) >= 0)
      ordered
    areaColumns = collectAreas()
    metricSource = (m) ->
      if m == "lag_avg" then lagByEdition
      else if m == "new_components_qty" then qtyByEdition
      else if m == "systems_with_new" then systemsWithNewByEdition
      else newUpgradedByEdition
    metricValueFromPoint = (m, p) ->
      if m == "lag_avg"
        lagValueWithUnit(p?.value, (lagUnitSel?.value or "days"))
      else if m == "new_components_qty" then +(p?.value or 0)
      else if m == "systems_with_new" then +(p?.value or 0)
      else if m == "new_systems" then +(p?.new_systems or 0)
      else +(p?.upgraded_systems or 0)
    metricShareDetailsFromPoint = (m, p) ->
      return null unless p?
      if m == "systems_with_new"
        total = +(p?.total_systems or 0)
        value = +(p?.value or 0)
        share = if p?.share_pct? then +(p.share_pct) else if total > 0 then (value / total * 100) else null
        { value: value, total: total, share_pct: share }
      else if m == "new_systems"
        total = +(p?.total_systems or 0)
        value = +(p?.new_systems or 0)
        share = if p?.new_share_pct? then +(p.new_share_pct) else if total > 0 then (value / total * 100) else null
        { value: value, total: total, share_pct: share }
      else if m == "upgraded_systems"
        total = +(p?.total_systems or 0)
        value = +(p?.upgraded_systems or 0)
        share = if p?.upgraded_share_pct? then +(p.upgraded_share_pct) else if total > 0 then (value / total * 100) else null
        { value: value, total: total, share_pct: share }
      else
        null
    tableCellValue = (m, p) ->
      if tableShowShare and metricSupportsShare(m)
        d = metricShareDetailsFromPoint(m, p)
        if d? and d.total > 0 and d.share_pct?
          "#{formatPct(d.share_pct)}%"
        else
          "0%"
      else
        metricValueFromPoint(m, p)
    renderComponentsByAreaTable = () ->
      return unless tableBody and tableHead
      src = metricSource(tableMetric) or []
      src = src.slice().sort((a, b) -> (+(b?.edition or 0)) - (+(a?.edition or 0)))
      headHtml = "<tr><th>Редакция</th>"
      areaColumns.forEach((a) ->
        headHtml += "<th>#{a}</th>"
      )
      headHtml += "</tr>"
      tableHead.innerHTML = headHtml
      tableBody.innerHTML = ""
      csvHeader = ["Редакция"].concat(areaColumns)
      csvLines = [csvHeader.map(escapeCsvField).join(",")]
      src.forEach((ed, i) ->
        editionNo = ed?.edition or (i + 1)
        dateLabel = ed?.date_label or ""
        meta = editionMeta[editionNo] or editionMeta[String(editionNo)] or {}
        editionLabel = meta.label or "#{editionNo}-я (#{dateLabel})"
        editionUrl = meta.url
        valueByArea = {}
        (ed?.data or []).forEach((p) -> valueByArea[p.area] = tableCellValue(tableMetric, p))
        tr = document.createElement("tr")
        td0 = document.createElement("td")
        td0.className = "fit"
        if editionUrl
          a = document.createElement("a")
          a.setAttribute("href", editionUrl)
          a.textContent = editionLabel
          td0.appendChild(a)
        else
          td0.textContent = editionLabel
        tr.appendChild(td0)
        rowCsv = [editionLabel]
        areaColumns.forEach((a) ->
          v = valueByArea[a]
          vv = if v? then v else 0
          td = document.createElement("td")
          td.style.textAlign = "right"
          td.textContent = vv
          tr.appendChild(td)
          rowCsv.push(vv)
        )
        tableBody.appendChild(tr)
        csvLines.push(rowCsv.map(escapeCsvField).join(","))
      )
      if csvLink
        suffix = if tableShowShare and metricSupportsShare(tableMetric) then "_pct" else ""
        csvLink.setAttribute("download", "area_upg_#{tableMetric}#{suffix}.csv")
        csvLink.setAttribute("href", "data:text/csv;charset=utf-8," + encodeURIComponent(csvLines.join("\n")))
    setActiveTableBtn = () ->
      btns = [tableBtnLag, tableBtnNewComponents, tableBtnSystemsNewComp, tableBtnNewSystems, tableBtnUpgradedSystems]
      btns.forEach((b) -> if b then b.style.opacity = "0.75")
      active = if tableMetric == "lag_avg" then tableBtnLag else if tableMetric == "new_components_qty" then tableBtnNewComponents else if tableMetric == "systems_with_new" then tableBtnSystemsNewComp else if tableMetric == "new_systems" then tableBtnNewSystems else tableBtnUpgradedSystems
      if active then active.style.opacity = "1"
      if tableBtnShare
        shareEnabled = tableShowShare and metricSupportsShare(tableMetric)
        tableBtnShare.style.background = if metricSupportsShare(tableMetric) then "#6699CC" else "gray"
        tableBtnShare.style.opacity = if metricSupportsShare(tableMetric) then (if shareEnabled then "1" else "0.75") else "0.45"
        tableBtnShare.style.pointerEvents = if metricSupportsShare(tableMetric) then "" else "none"
    redrawComponentsByArea = () ->
      idx = Math.max(0, Math.min(idx, maxIdx))
      lagItem = lagByEdition[idx] or {}
      qtyItem = qtyByEdition[idx] or {}
      sysNewItem = systemsWithNewByEdition?[idx] or {}
      newUpgItem = newUpgradedByEdition?[idx] or {}
      areaColor = {}
      (lagItem.data or []).forEach((p) -> areaColor[p.area] = p.color if p?.area?)
      editionNo = lagItem.edition or (idx + 1)
      dateLabel = lagItem.date_label or ""
      labelEl.textContent = "#{editionNo}-я редакция (#{dateLabel})"
      metric = metricSel?.value or "lag_avg"
      showLagUnit = (metric == "lag_avg")
      if lagUnitLabel then lagUnitLabel.style.display = if showLagUnit then "" else "none"
      if lagUnitWrap then lagUnitWrap.style.display = if showLagUnit then "" else "none"
      lagUnit = (lagUnitSel?.value or "days")
      if metric == "lag_avg"
        lagDataConverted = (lagItem.data or []).map((p) ->
          { area: p.area, color: p.color, value: lagValueWithUnit(p.value, lagUnit) }
        )
        lagYLabel = if lagUnit == "quarters" then "Средняя задержка внедрения (кварталы)" else "Средняя задержка внедрения (дни)"
        draw_area_upg(lagDataConverted, "area_upg_chart", "Гистограмма средней задержки внедрения самых свежих компонент по областям", lagYLabel)
      else if metric == "new_components_qty"
        qtyData = (qtyItem.data or []).map((p) ->
          { area: p.area, color: p.color, value: +(p.value or 0) }
        )
        draw_area_upg(qtyData, "area_upg_chart", "Гистограмма количества новых компонент по областям", "Количество компонент")
      else if metric == "systems_with_new"
        draw_area_upg(sysNewItem.data or [], "area_upg_chart", "Гистограмма количества систем с новыми компонентами по областям", "Количество систем")
      else if metric == "new_systems"
        dataNew = (newUpgItem.data or []).map((p) ->
          { area: p.area, color: (areaColor[p.area] or "#2ca02c"), value: +(p.new_systems or 0), total_systems: +(p.total_systems or 0), share_pct: p.new_share_pct }
        )
        draw_area_upg(dataNew, "area_upg_chart", "Гистограмма количества новых систем по областям", "Количество систем")
      else if metric == "upgraded_systems"
        dataUpg = (newUpgItem.data or []).map((p) ->
          { area: p.area, color: (areaColor[p.area] or "#ff7f0e"), value: +(p.upgraded_systems or 0), total_systems: +(p.total_systems or 0), share_pct: p.upgraded_share_pct }
        )
        draw_area_upg(dataUpg, "area_upg_chart", "Гистограмма количества обновлённых систем по областям", "Количество систем")
      else
        draw_area_upg(sysNewItem.data or [], "area_upg_chart", "Гистограмма количества систем с новыми компонентами по областям", "Количество систем")
      renderComponentsByAreaTable()
      setActiveTableBtn()
      prevColor = if idx <= 0 then "#d0d0d0" else "#6699CC"
      nextColor = if idx >= maxIdx then "#d0d0d0" else "#6699CC"
      d3.select(prevBtn).select("polygon").attr("fill", prevColor)
      d3.select(nextBtn).select("polygon").attr("fill", nextColor)

    prevBtn.addEventListener("click", () ->
      return if idx <= 0
      idx -= 1
      redrawComponentsByArea()
    )
    nextBtn.addEventListener("click", () ->
      return if idx >= maxIdx
      idx += 1
      redrawComponentsByArea()
    )
    if lagUnitSel
      lagUnitSel.addEventListener("change", redrawComponentsByArea)
    if metricSel
      metricSel.addEventListener("change", redrawComponentsByArea)
    if tableBtnLag
      tableBtnLag.addEventListener("click", (e) -> e.preventDefault(); tableMetric = "lag_avg"; tableShowShare = false unless metricSupportsShare(tableMetric); renderComponentsByAreaTable(); setActiveTableBtn())
    if tableBtnNewComponents
      tableBtnNewComponents.addEventListener("click", (e) -> e.preventDefault(); tableMetric = "new_components_qty"; tableShowShare = false unless metricSupportsShare(tableMetric); renderComponentsByAreaTable(); setActiveTableBtn())
    if tableBtnSystemsNewComp
      tableBtnSystemsNewComp.addEventListener("click", (e) -> e.preventDefault(); tableMetric = "systems_with_new"; renderComponentsByAreaTable(); setActiveTableBtn())
    if tableBtnNewSystems
      tableBtnNewSystems.addEventListener("click", (e) -> e.preventDefault(); tableMetric = "new_systems"; renderComponentsByAreaTable(); setActiveTableBtn())
    if tableBtnUpgradedSystems
      tableBtnUpgradedSystems.addEventListener("click", (e) -> e.preventDefault(); tableMetric = "upgraded_systems"; renderComponentsByAreaTable(); setActiveTableBtn())
    if tableBtnShare
      tableBtnShare.addEventListener("click", (e) ->
        e.preventDefault()
        return unless metricSupportsShare(tableMetric)
        tableShowShare = !tableShowShare
        renderComponentsByAreaTable()
        setActiveTableBtn()
      )
    redrawComponentsByArea()

  # list_upg: матрица, фильтрация по редакциям и местам
  if typeof chartData != "undefined" and document.getElementById("matrix_chart")
    listStartEd = document.getElementById("list-upg-edition-start")
    listEndEd   = document.getElementById("list-upg-edition-end")
    listStartRank = document.getElementById("list-upg-rank-start")
    listEndRank   = document.getElementById("list-upg-rank-end")
    if listStartEd and listEndEd and listStartRank and listEndRank
      origMatrixData = chartData.slice()
      updateListUpg = ->
        esVal = listStartEd.value
        eeVal = listEndEd.value
        rkFrom = parseInt(listStartRank.value) or minRank
        rkTo   = parseInt(listEndRank.value) or maxRank
        if rkFrom > rkTo then [rkFrom, rkTo] = [rkTo, rkFrom]
        allowed = []
        idxFrom = editions.indexOf(esVal)
        idxTo   = editions.indexOf(eeVal)
        if idxFrom < 0 or idxTo < 0
          allowed = editions
        else
          if idxFrom > idxTo then [idxFrom, idxTo] = [idxTo, idxFrom]
          allowed = editions.slice(idxFrom, idxTo + 1)
        filteredMatrix = origMatrixData.filter((row) ->
          ed = row.edition
          rk = row.rank
          allowed.includes(ed) and rk? and rk >= rkFrom and rk <= rkTo
        )
        drawMatrix(filteredMatrix, "matrix_chart")
      # Инициализация списков редакций и мест
      editions = Array.from(new Set(origMatrixData.map((r) -> r.edition))).sort()
      ranks = Array.from(new Set(origMatrixData.map((r) -> r.rank))).sort((a, b) -> a - b)
      minRank = ranks[0] or 1
      maxRank = ranks[ranks.length - 1] or getMaxRank()
      # Заполняем селекторы редакций
      ;[listStartEd, listEndEd].forEach((sel, idx) ->
        while sel.options.length > 0
          sel.remove(0)
        editions.forEach((ed, i) ->
          opt = document.createElement("option")
          opt.value = ed
          opt.text = formatEditionDate(ed)
          sel.appendChild(opt)
        )
        if idx == 0
          sel.selectedIndex = 0
        else
          sel.selectedIndex = sel.options.length - 1
      )
      # Заполняем селекторы мест
      ;[listStartRank, listEndRank].forEach((sel, idx) ->
        while sel.options.length > 0
          sel.remove(0)
        ranks.forEach((rk) ->
          opt = document.createElement("option")
          opt.value = rk
          opt.text = rk
          sel.appendChild(opt)
        )
        if idx == 0
          sel.selectedIndex = 0
        else
          sel.selectedIndex = sel.options.length - 1
      )
      # Начальная отрисовка с учетом селекторов
      updateListUpg()
      listStartEd.addEventListener("change", updateListUpg)
      listEndEd.addEventListener("change", updateListUpg)
      listStartRank.addEventListener("change", updateListUpg)
      listEndRank.addEventListener("change", updateListUpg)

  # new_upg: edition range selector — filter charts, table, CSV (client-side)
  initAreaAndListUpgStats()

  initNewUpgStats = ->
    newUpgStartSel = document.getElementById("new-upg-edition-start")
    newUpgEndSel   = document.getElementById("new-upg-edition-end")
    newUpgGraphSel = document.getElementById("new-upg-bar-graph-selector")
    newUpgChartEl  = document.getElementById("chart_new_vs_upgraded")
    return unless newUpgStartSel and newUpgEndSel and newUpgChartEl and typeof window.chartData != "undefined"
    newUpgCharts =
      total:
        id: "chart_new_vs_upgraded"
        wrapperId: "new-upg-bar-graph-total"
        dataKey: "chartData"
        title: "Гистограмма количества новых и обновлённых систем по редакциям"
        xLabel: "Дата (ММ.ГГ)"
        yLabel: "Количество систем"
      rpeak_pct:
        id: "chart_new_vs_upgraded_rpeak_pct"
        wrapperId: "new-upg-bar-graph-rpeak-pct"
        dataKey: "chartDataRpeakPct"
        title: "Гистограмма доли производительности Rpeak новых и обновлённых систем"
        xLabel: "Дата (ММ.ГГ)"
        yLabel: "% Rpeak"
      rmax_pct:
        id: "chart_new_vs_upgraded_rmax_pct"
        wrapperId: "new-upg-bar-graph-rmax-pct"
        dataKey: "chartDataRmaxPct"
        title: "Гистограмма доли производительности Rmax новых и обновлённых систем"
        xLabel: "Дата (ММ.ГГ)"
        yLabel: "% Rmax"
    updateNewUpgEditionEndOptions = () ->
      return unless newUpgEndSel
      for i in [0...newUpgEndSel.options.length]
        newUpgEndSel.options[i].hidden = false
    updateNewUpgEditionStartOptions = () ->
      return unless newUpgStartSel
      for i in [0...newUpgStartSel.options.length]
        newUpgStartSel.options[i].hidden = false
    sliceNewUpgChartData = sliceChartSeriesByEditionRange
    updateNewUpg = () ->
      updateNewUpgEditionEndOptions()
      updateNewUpgEditionStartOptions()
      startVal = parseInt(newUpgStartSel?.value, 10) or 1
      maxEd = (window.editionDatesNewUpg or []).length or 1
      endVal = parseInt(newUpgEndSel?.value, 10) or maxEd
      startVal = Math.max(1, Math.min(startVal, maxEd))
      endVal = Math.max(1, Math.min(endVal, maxEd))
      edFrom = Math.min(startVal, endVal)
      edTo = Math.max(startVal, endVal)
      selected = resolveGraphChoice("new-upg-bar-graph-selector", newUpgCharts, "total")
      applyGraphVisibility(newUpgCharts, selected.key)
      filteredMain = sliceNewUpgChartData(window.chartData, edFrom, edTo)
      numPoints = (filteredMain[0]?.data?.length) or 0
      minChartWidth = Math.max(1000, numPoints * 40)
      newUpgChartKeys = Object.keys(newUpgCharts)
      newUpgChartKeys.forEach((key) ->
        cfg = newUpgCharts[key]
        el = document.getElementById(cfg.id)
        if el then el.style.minWidth = minChartWidth + "px"
      )
      cfg = selected.config
      if cfg?
        filteredSelected = sliceNewUpgChartData(window[cfg.dataKey], edFrom, edTo)
        if filteredSelected.length > 0 and filteredSelected[0].data and filteredSelected[0].data.length > 0
          draw_new_vs_upgraded_new(filteredSelected, cfg.id, cfg.title, cfg.xLabel, cfg.yLabel)
      rows = document.querySelectorAll("table.table tbody tr[data-edition-index]")
      for i in [0...rows.length]
        idx = parseInt(rows[i].getAttribute("data-edition-index"), 10)
        rows[i].style.display = (idx >= edFrom and idx <= edTo) ? "" : "none"
      summary = window.ratingsSummaryNewUpg or []
      filteredSummary = summary.filter((r) -> r.edition_index >= edFrom and r.edition_index <= edTo)
      header = "Редакция,Новые машины,Обновлённые машины,Новые и обновлённые машины,% Новых машин,% Обновлённых машин,% Новых и обновлённых машин,% Rpeak новых машин,% Rmax новых машин,% Rpeak обновлённых машин,% Rmax обновлённых машин,% Rpeak новых и обновлённых машин,% Rmax новых и обновлённых машин"
      csvLines = [header]
      filteredSummary.forEach((r) ->
        pctNew = if r.pct_new != null then r.pct_new else ""
        pctUpg = if r.pct_upg != null then r.pct_upg else ""
        pctNewUpg = if r.pct_new_upg != null then r.pct_new_upg else ""
        pctRpeakNew = if r.pct_rpeak_new != null then r.pct_rpeak_new else ""
        pctRmaxNew = if r.pct_rmax_new != null then r.pct_rmax_new else ""
        pctRpeakUpg = if r.pct_rpeak_upg != null then r.pct_rpeak_upg else ""
        pctRmaxUpg = if r.pct_rmax_upg != null then r.pct_rmax_upg else ""
        pctRpeakNewUpg = if r.pct_rpeak_new_upg != null then r.pct_rpeak_new_upg else ""
        pctRmaxNewUpg = if r.pct_rmax_new_upg != null then r.pct_rmax_new_upg else ""
        csvLines.push([escapeCsvField(r.edition_label), r.new_machines, r.upgraded_machines, r.total_machines, pctNew, pctUpg, pctNewUpg, pctRpeakNew, pctRmaxNew, pctRpeakUpg, pctRmaxUpg, pctRpeakNewUpg, pctRmaxNewUpg].join(","))
      )
      csvStr = csvLines.join("\n")
      linkEl = document.getElementById("download_new_upg")
      if linkEl
        linkEl.setAttribute("href", "data:text/csv;charset=utf-8," + encodeURIComponent(csvStr))
    updateNewUpg()
    newUpgStartSel.addEventListener("change", updateNewUpg)
    newUpgEndSel.addEventListener("change", updateNewUpg)
    if newUpgGraphSel
      newUpgGraphSel.addEventListener("change", updateNewUpg)

  initNewUpgStats()

@draw_new_vs_upgraded_new = (data, src_id, title, x_label, y_label) ->
  return unless data and data.length > 0 and data[0].data and data[0].data.length > 0
  # Подготовка данных: парсим даты только если это ещё строки (при повторной отрисовке уже Date)
  for i in [0..data.length - 1]
    for j in [0..data[i].data.length - 1]
      d = data[i].data[j][0]
      unless d instanceof Date
        s = String(d).split("-")
        data[i].data[j][0] = new Date(+s[0], +s[1] - 1)

  # Функция загрузки
  func = () ->
    el = document.getElementById(src_id)
    return unless el
    width = el.offsetWidth
    height = Math.max(320, Math.min(600, el.offsetWidth * 0.6))

    margin =
      top: 10
      bottom: 100
      right: 10
      left: 80

    container = d3.selectAll("div").filter(() -> d3.select(this).attr("id") == src_id)
    container.selectAll("*").remove()
    headerEl = document.getElementById(src_id + "_header")
    headerContainer = if headerEl then d3.select(headerEl) else container
    if headerEl
      headerContainer.selectAll("*").remove()
    topContainer = headerContainer

    # Заголовок
    appendChartHeader(topContainer, title, "20px")

    stickyYAxisSel = null
    # Функция обновления шкалы Y по видимым сериям (гибкая шкала при скрытии серий)
    updateYScale = () ->
      visibleMax = 0
      for idx in [0...data.length]
        sel = svg.selectAll(".layer-" + idx)
        continue if sel.empty()
        isHidden = sel.classed("hidden")
        unless isHidden
          seriesMax = d3.max(data[idx].data, (d) -> d[1])
          visibleMax = Math.max(visibleMax, seriesMax) if seriesMax?
      visibleMax = Math.max(visibleMax, 1)
      y_scale.domain([0, visibleMax])
      axisSel = if stickyYAxisSel then stickyYAxisSel else svg.select("g.axis-y")
      axisSel.call(y_axis)
      data.forEach((dataset, idx) ->
        layerSel = svg.selectAll(".layer-" + idx)
        layerSel.filter("rect").attr("y", (d) -> y_scale(d[1])).attr("height", (d) -> height - margin.bottom - y_scale(d[1]))
        layerSel.filter("circle").attr("cy", (d) -> y_scale(d[1]))
      )

    # Кнопки для переключения (в заголовке вне скролла, если есть _header)
    buttons = topContainer.append("div").style("margin-bottom", "10px")
    data.forEach((dataset, i) ->
      buttons.append("button")
             .text(dataset.name)
             .style("background-color", dataset.color)
             .style("color", "white")
             .style("border", "2px solid #000")
             .style("border-radius", "5px")
             .style("padding", "5px 10px")
             .style("margin-right", "10px")
             .style("cursor", "pointer")
             .style("font-weight", "bold")
             .attr("class", "toggle-btn-" + i)
             .on("click", () ->
               chartLayers = svg.selectAll(".layer-" + i)
               chartLayers.classed("hidden", (d, j, nodes) ->
                   !d3.select(nodes[j]).classed("hidden")
                 )
               isHidden = chartLayers.classed("hidden")
               btn = topContainer.select(".toggle-btn-" + i)
               btn.style("opacity", if isHidden then 0.5 else 1)
               updateYScale()
             )
    )

    svg = container.append("svg")
                   .attr("style", "width:" + width + "px; height:" + height + "px")
                   .attr("id", "svg_" + src_id)

    # Шкалы
    x_scale = d3.scaleBand()
                .domain(data[0].data.map((d) -> d[0]).sort((a, b) -> a - b))
                .range([margin.left, width - margin.right])
                .padding(0.2) # Увеличиваем отступы между столбцами

    y_scale = d3.scaleLinear()
                .domain([0, d3.max(data, (dataset) -> d3.max(dataset.data, (d) -> d[1]))])
                .range([height - margin.bottom, margin.top])

    # Оси
    x_axis = d3.axisBottom(x_scale).tickFormat(d3.timeFormat("%m.%Y"))
    y_axis = d3.axisLeft(y_scale)

    svg.append("g")
       .attr("transform", "translate(0," + (height - margin.bottom) + ")")
       .call(x_axis)
       .selectAll("text")
       .style("text-anchor", "end")
       .attr("transform", "rotate(-45)")
       .style("font-size", "12px")

    svg.append("g")
       .attr("class", "axis-y")
       .attr("transform", "translate(" + margin.left + ",0)")
       .call(y_axis)

    scrollParent = container.node().parentNode
    hasSticky = scrollParent and (d3.select(scrollParent).classed("new-upg-charts-scroll") or d3.select(scrollParent).classed("freshest-charts-scroll"))
    if hasSticky
      oldSticky = scrollParent.querySelector(".new-upg-sticky-y-axis")
      if oldSticky then oldSticky.remove()
      stickyW = margin.left
      stickyDiv = document.createElement("div")
      stickyDiv.className = "new-upg-sticky-y-axis"
      stickyDiv.style.cssText = "position: sticky; left: 0; width: " + stickyW + "px; min-width: " + stickyW + "px; height: " + height + "px; flex-shrink: 0; background: #fff; z-index: 1; overflow: visible;"
      scrollParent.insertBefore(stickyDiv, container.node())
      stickySvg = d3.select(stickyDiv).append("svg").attr("width", stickyW).attr("height", height).attr("style", "display: block; overflow: visible;")
      stickyYAxisSel = stickySvg.append("g").attr("class", "axis-y").attr("transform", "translate(" + (stickyW - 1) + ",0)").call(y_axis)
      # Y-axis label in sticky so it stays visible (main svg is shifted left); extra gap from axis so it doesn't intersect tick values
      yLabelGap = 70
      yLabelX = (stickyW - 1) - yLabelGap
      yLabelY = height / 2
      stickySvg.append("text")
        .attr("class", "y-axis-label")
        .attr("transform", "rotate(-90, " + yLabelX + ", " + yLabelY + ")")
        .attr("x", yLabelX)
        .attr("y", yLabelY)
        .attr("dy", "0.35em")
        .style("text-anchor", "middle")
        .style("font-family", "Arial")
        .style("font-size", "14px")
        .text(y_label)
      svg.select("g.axis-y").remove()
      container.node().style.marginLeft = "-" + margin.left + "px"

    # Подпись для оси X
    svg.append("text")
       .attr("transform", "translate(" + (width / 2) + "," + (height - margin.bottom + 70) + ")")
       .style("text-anchor", "middle")
       .style("font-family", "Arial")
       .style("font-size", "14px")
       .text("Дата (ММ.ГГ)")

    # Подпись для оси Y (только если нет sticky — иначе она в sticky div)
    unless hasSticky
      appendYAxisLabel(svg, margin.left, height, y_label)

    # Добавляем столбцы и точки
    data.forEach((dataset, i) ->
      if dataset.name == "Новые и обновлённые системы"
        # Рисуем точку для суммарного показателя
        svg.selectAll(".dot-" + i)
           .data(dataset.data)
           .enter()
           .append("circle")
           .attr("cx", (d) -> x_scale(d[0]) + x_scale.bandwidth() / 2) # Центр точки над датой
           .attr("cy", (d) -> y_scale(d[1]))
           .attr("r", 5)
           .attr("fill", dataset.color)
           .attr("stroke", "black")
           .attr("stroke-width", "1px")
           .attr("class", "layer-" + i)
      else if dataset.name == "Новые системы"
        # Рисуем столбцы новых систем слева от даты
        svg.selectAll(".bar-new-" + i)
           .data(dataset.data)
           .enter()
           .append("rect")
           .attr("x", (d) -> x_scale(d[0]) + x_scale.bandwidth() * 0.1) # Смещаем влево
           .attr("y", (d) -> y_scale(d[1]))
           .attr("width", x_scale.bandwidth() * 0.3) # Уменьшаем ширину
           .attr("height", (d) -> height - margin.bottom - y_scale(d[1]))
           .attr("fill", dataset.color)
           .attr("stroke", "black")
           .attr("stroke-width", "1px")
           .attr("class", "layer-" + i)
      else if dataset.name == "Обновлённые системы"
        # Рисуем столбцы обновлённых систем справа от даты
        svg.selectAll(".bar-upg-" + i)
           .data(dataset.data)
           .enter()
           .append("rect")
           .attr("x", (d) -> x_scale(d[0]) + x_scale.bandwidth() * 0.6) # Смещаем вправо
           .attr("y", (d) -> y_scale(d[1]))
           .attr("width", x_scale.bandwidth() * 0.3) # Уменьшаем ширину
           .attr("height", (d) -> height - margin.bottom - y_scale(d[1]))
           .attr("fill", dataset.color)
           .attr("stroke", "black")
           .attr("stroke-width", "1px")
           .attr("class", "layer-" + i)
      else
        # Произвольные серии (напр. "С свежими CPU/GPU"): столбцы рядом по дате
        n = data.length
        barW = x_scale.bandwidth() * (0.9 / n) * 0.85
        barOffset = (x_scale.bandwidth() * (0.05 + i * (0.9 / n)))
        svg.selectAll(".bar-gen-" + i)
           .data(dataset.data)
           .enter()
           .append("rect")
           .attr("x", (d) -> x_scale(d[0]) + barOffset)
           .attr("y", (d) -> y_scale(d[1]))
           .attr("width", barW)
           .attr("height", (d) -> height - margin.bottom - y_scale(d[1]))
           .attr("fill", dataset.color)
           .attr("stroke", "black")
           .attr("stroke-width", "1px")
           .attr("class", "layer-" + i)
    )

  # Добавляем обработчик загрузки (цепочка, чтобы не перезаписать другие графики)
  oldOnload = window.onload
  window.onload = () ->
    if oldOnload then oldOnload()
    func()
  # Вызываем сразу, чтобы график отрисовался при вызове (в т.ч. при смене диапазона редакций)
  func()

@draw_area_upg = (points, src_id, title, y_label) ->
  return unless Array.isArray(points)
  func = () ->
    el = document.getElementById(src_id)
    return unless el
    width = Math.max(el.offsetWidth or 900, 900)
    height = Math.max(340, Math.min(560, width * 0.55))
    margin =
      top: 15
      right: 20
      bottom: 130
      left: 90

    chartContainers = prepareChartContainers(src_id)
    container = chartContainers.container
    headerContainer = chartContainers.headerContainer
    appendChartHeader(headerContainer, title)

    safePoints = points.map((p) ->
      totalSystems = +(p.total_systems or 0)
      value = +(p.value or 0)
      sharePct = if p.share_pct? then +(p.share_pct) else if totalSystems > 0 then (value / totalSystems * 100) else null
      { area: p.area, value: value, color: p.color, total_systems: totalSystems, share_pct: sharePct }
    ).filter((p) -> p.area?)
    return if safePoints.length == 0

    xScale = d3.scaleBand()
      .domain(safePoints.map((p) -> p.area))
      .range([margin.left, width - margin.right])
      .padding(0.2)

    maxVal = d3.max(safePoints, (p) -> p.value) or 0
    yScale = d3.scaleLinear()
      .domain([0, Math.max(1, maxVal)])
      .range([height - margin.bottom, margin.top])

    svg = container.append("svg")
      .attr("style", "width:#{width}px; height:#{height}px")
      .attr("id", "svg_" + src_id)

    svg.append("g")
      .attr("transform", "translate(0,#{height - margin.bottom})")
      .call(d3.axisBottom(xScale))
      .selectAll("text")
      .style("text-anchor", "end")
      .attr("transform", "rotate(-35)")
      .style("font-size", "12px")

    svg.append("g")
      .attr("transform", "translate(#{margin.left},0)")
      .call(d3.axisLeft(yScale))

    appendYAxisLabel(svg, margin.left, height, y_label)

    bars = svg.selectAll(".bar")
      .data(safePoints)
      .enter()
      .append("rect")
      .attr("class", "bar")
      .attr("x", (d) -> xScale(d.area))
      .attr("width", xScale.bandwidth())
      .attr("y", (d) -> yScale(Math.max(0, d.value)))
      .attr("height", (d) -> height - margin.bottom - yScale(Math.max(0, d.value)))
      .attr("fill", (d) -> d.color or "#6699CC")
      .attr("stroke", "black")
      .attr("stroke-width", "1px")
    bars.append("title")
      .text((d) ->
        v = d.value
        valueLabel = if Math.abs(v - Math.round(v)) < 0.001 then Math.round(v) else (Math.round(v * 100) / 100)
        if d.share_pct? and d.total_systems > 0
          pctRounded = Math.round(d.share_pct * 100) / 100
          "#{d.area}: #{valueLabel} / #{d.total_systems} (#{pctRounded}%)"
        else
          "#{d.area}: #{valueLabel}"
      )

    svg.selectAll(".bar-label")
      .data(safePoints)
      .enter()
      .append("text")
      .attr("class", "bar-label")
      .attr("x", (d) -> xScale(d.area) + xScale.bandwidth() / 2)
      .attr("y", (d) -> yScale(Math.max(0, d.value)) - 5)
      .attr("text-anchor", "middle")
      .style("font-size", "11px")
      .text((d) ->
        v = d.value
        valueLabel = if Math.abs(v - Math.round(v)) < 0.001 then Math.round(v) else (Math.round(v * 100) / 100)
        if d.share_pct? and d.total_systems > 0
          pctRounded = Math.round(d.share_pct * 100) / 100
          "#{valueLabel} (#{pctRounded}%)"
        else
          valueLabel
      )
  func()

@draw_area_upg_grouped = (series, src_id, title, y_label) ->
  return unless Array.isArray(series) and series.length > 0
  baseAreas = ((series[0] or {}).data or []).map((p) -> p.area).filter((a) -> a?)
  return if baseAreas.length == 0
  func = () ->
    el = document.getElementById(src_id)
    return unless el
    width = Math.max(el.offsetWidth or 900, 900)
    height = Math.max(360, Math.min(580, width * 0.58))
    margin = { top: 15, right: 20, bottom: 130, left: 90 }

    chartContainers = prepareChartContainers(src_id)
    container = chartContainers.container
    headerContainer = chartContainers.headerContainer
    appendChartHeader(headerContainer, title)

    x0 = d3.scaleBand().domain(baseAreas).range([margin.left, width - margin.right]).padding(0.2)
    x1 = d3.scaleBand().domain(series.map((s) -> s.name)).range([0, x0.bandwidth()]).padding(0.1)
    maxVal = d3.max(series, (s) -> d3.max((s.data or []), (p) -> +(p.value or 0))) or 0
    y = d3.scaleLinear().domain([0, Math.max(1, maxVal)]).range([height - margin.bottom, margin.top])

    svg = container.append("svg").attr("style", "width:#{width}px; height:#{height}px").attr("id", "svg_" + src_id)
    svg.append("g")
      .attr("transform", "translate(0,#{height - margin.bottom})")
      .call(d3.axisBottom(x0))
      .selectAll("text")
      .style("text-anchor", "end")
      .attr("transform", "rotate(-35)")
      .style("font-size", "12px")
    svg.append("g").attr("transform", "translate(#{margin.left},0)").call(d3.axisLeft(y))
    appendYAxisLabel(svg, margin.left, height, y_label)

    normalized = baseAreas.map((area) ->
      row = { area: area }
      series.forEach((s) ->
        hit = (s.data or []).find((p) -> p.area == area)
        row[s.name] = +(hit?.value or 0)
      )
      row
    )

    groups = svg.selectAll(".group").data(normalized).enter().append("g").attr("class", "group").attr("transform", (d) -> "translate(#{x0(d.area)},0)")
    groups.selectAll("rect")
      .data((d) -> series.map((s) -> { key: s.name, value: d[s.name], color: s.color }))
      .enter()
      .append("rect")
      .attr("x", (d) -> x1(d.key))
      .attr("y", (d) -> y(d.value))
      .attr("width", x1.bandwidth())
      .attr("height", (d) -> height - margin.bottom - y(d.value))
      .attr("fill", (d) -> d.color)
      .attr("stroke", "black")
      .attr("stroke-width", "1px")

    legend = headerContainer.append("div").style("margin-bottom", "8px")
    series.forEach((s) ->
      item = legend.append("span").style("display", "inline-block").style("margin-right", "14px").style("font-size", "13px")
      item.append("span").style("display", "inline-block").style("width", "10px").style("height", "10px").style("background", s.color).style("margin-right", "6px")
      item.append("span").text(s.name)
    )
  func()


# "YYYY-MM" -> "MM.YY" for list_upg x-axis
formatEditionDate = (s) ->
  return s unless s
  parts = String(s).split("-")
  if parts.length >= 2 then parts[1] + "." + (if parts[0].length >= 2 then parts[0].slice(-2) else parts[0]) else s

@drawMatrix = (data, containerId) ->
  container = d3.select("##{containerId}")
  container.selectAll("*").remove()

  # Цветовая шкала для статусов
  statusColors =
    new: "blue"
    updated: "#FFA500"
    moved_up: "green"
    moved_down: "#B22222"


  # Русские названия статусов
  statusLabels =
    new: "Новая"
    updated: "Обновленная"
    moved_up: "Поднялась"
    moved_down: "Опустилась"

  # Кнопки для фильтрации
  activeFilters = { new: true, updated: true, moved_up: true, moved_down: true }
  buttons = container.append("div")
    .style("display", "flex")
    .style("justify-content", "center")
    .style("align-items", "center")
    .style("flex-wrap", "wrap")
    .style("gap", "10px")
    .style("margin-bottom", "10px")

  Object.keys(statusColors).forEach((status) ->
    buttons.append("button")
      .text(statusLabels[status])  # Используем русские названия
      .style("background-color", statusColors[status])
      .style("color", "white")
      .style("border", "2px solid #000")
      .style("border-radius", "5px")
      .style("padding", "5px 10px")
      .style("cursor", "pointer")
      .style("font-weight", "bold")
      .attr("class", "toggle-btn-" + status)
      .on("click", ->
        activeFilters[status] = !activeFilters[status]
        # Обновляем прозрачность кнопки
        btn = d3.select(".toggle-btn-" + status)
        btn.style("opacity", if activeFilters[status] then 1 else 0.5)

        # Обновляем видимость и окрашивание клеток
        container.selectAll(".cell").each((d, i, nodes) ->
          cellGroup = d3.select(nodes[i])
          applyMatrixCellVisibility(cellGroup, d, activeFilters, statusColors, x, y)
        )
      )
  )

  scaffold = buildHeatmapScaffold({
    containerId: containerId
    clearContainer: false
    data: data
    margin: { top: 20, right: 20, bottom: 80, left: 70 }
    editionSort: (a, b) -> if a > b then 1 else if a < b then -1 else 0
    rankSort: (a, b) -> a - b
    fallbackRankAscending: true
    xRange: (width) -> [0, width]
    yRange: (width, height) -> [0, height]
    xTickFormat: formatEditionDate
    extraBottom: 0
  })
  return unless scaffold?
  { svg, x, y, width } = scaffold

  # Рисуем клетки матрицы
  svg.selectAll(".cell")
    .data(data)
    .enter()
    .append("g")
    .attr("class", "cell")
    .each((d, i, nodes) ->
      cellGroup = d3.select(nodes[i])
      cellWidth = x.bandwidth()
      cellHeight = y.bandwidth()

      # Всегда создаем две половины клетки
      # Левая половина
      cellGroup.append("rect")
        .attr("class", "left-half")
        .attr("x", x(d.edition))
        .attr("y", y(d.rank))
        .attr("height", cellHeight)
        .attr("stroke", "black")
        .attr("stroke-width", 0.4)

      # Правая половина
      cellGroup.append("rect")
        .attr("class", "right-half")
        .attr("x", x(d.edition) + cellWidth / 2)
        .attr("y", y(d.rank))
        .attr("height", cellHeight)
        .attr("stroke", "black")
        .attr("stroke-width", 0.4)

      appendHeatmapHighlightRects(cellGroup, x, y)
      applyMatrixCellVisibility(cellGroup, d, activeFilters, statusColors, x, y)

      # Подсветка одной системы по всем редакциям при наведении
      if d.machine_id != null and d.machine_id != undefined
        keyMid = (row) -> if row.machine_key? then row.machine_key else row.machine_id
        cellGroup.on("mouseenter", (d) ->
          applyMachineHoverHighlight(containerId, d, keyMid)
        ).on("mouseleave", ->
          clearMachineHoverHighlight(containerId)
        )

      # Добавляем подсказку
      cellGroup.append("title")
        .text((d) ->
          tags = []

          if d.new_upd_status
            tags.push(statusLabels[d.new_upd_status])  # Используем русские названия
          if d.pos_status == "moved_up"
            tags.push("▲ #{d.rank_change || 'N/A'}")
          else if d.pos_status == "moved_down"
            tags.push("▽ #{Math.abs(d.rank_change) || 'N/A'}")

          tagsText = if tags.length > 0 then tags.join(", ") else "Без тегов"
          editionLabel = if d.list_num? and String(d.list_num).trim() != "" then d.list_num else formatEditionDate(d.edition)

          sysLine = heatmapTooltipSystemLine(d)
          "Редакция: #{editionLabel}, Место: #{d.rank}\n" +
          "Теги: #{tagsText}#{sysLine}"
        )
    )
