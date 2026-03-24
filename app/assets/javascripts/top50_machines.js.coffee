@test_fun = (text) ->
  #dsdfgdsfsa
  console.log("AAAAAAAAAAAAAAAAAAAAAAA" + text)

# Max rank (list size) from page or fallback; set by stats view as window.TOP50_MAX_RANK
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

heatmapTooltipSystemLineWithId = (d) ->
  lines = []
  if d.machine_id != null and d.machine_id != undefined
    lines.push "Система: #{heatmapTooltipMachineLabel(d)} (ID: #{d.machine_id})"
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

# drawing performance chart
@draw_performance = (data, src_id, title, x_label, y_label, COLORS = d3.schemeSet1, is_performance = false) ->
  for i in [0..data.length - 1]
    data[i].color = i
    for j in [0..data[i].data.length - 1]
      s = data[i].data[j][0].split(".")
      data[i].data[j][0] = new Date(+s[2], +s[1] - 1, +s[0])
      data[i].data[j][1] = +data[i].data[j][1]

  console.log(data)

  # onload function
  func = () ->
    width = document.getElementById(src_id).offsetWidth
    height = 550

    margin =
      top : 10
      bottom : 80
      right : 10
      left : 80

    container = d3.selectAll("div").filter(() -> d3.select(this).attr("id") == src_id)
            
    container.append("div")
              .text(title)
              .style("font-family", "Arial")
              .style("font-size", "24px")
              .style("border-radius", "7px")
              .style("font-weight", "500")
              .style("padding", "20px  0px")
              .style("line-height", "25px")
              .style("text-align", "center")
              .style("float", "center")

    legend = add_legend(container, data, COLORS)

    buttons = container.append("g").attr("id", "buttons")

    # changing view buttons
    line_button = buttons.append("div")
              .text("line")
              .attr("class", "button")
              .style("background", "#6699CC")
              .style("float", "right")
              .attr("name", "type")
              .property("checked", "true")

    log_button = buttons.append("div")
              .text("log")
              .attr("class", "button")
              .style("background", "gray")
              .style("float", "right")
              .attr("name", "type")
              .property("checked", "false")

    if (!is_performance)
      bar_button = buttons.append("div")
                .text("bar")
                .attr("class", "button")
                .style("background", "gray")
                .style("float", "right")
                .attr("name", "type")
                .property("checked", "false")

    # table control processing
    table_control = d3.selectAll("g").filter(() -> d3.select(this).attr("id") == "table_control_" + src_id)
    mode = [true, false, false]
    table = d3.selectAll("table").filter(() -> d3.select(this).attr("id") == "table_" + src_id)
    table_control.selectAll("div").filter(() -> d3.select(this).attr("id") == "0")
                .property("checked", true)
                .each(() -> console.log(d3.select(this).property("checked")))
    table_control.selectAll("div").filter(() -> d3.select(this).attr("id") == "1")
                .property("checked", false)
                .each(() -> console.log(d3.select(this).property("checked")))
    table_control.selectAll("div").filter(() -> d3.select(this).attr("id") == "2")
                .property("checked", false)
                .each(() -> console.log(d3.select(this).property("checked")))

    # adding svg elements
    svg = container.append("svg").attr("style", "width:100%; height:" + height + "px").attr("id", "svg_" + src_id)

    add_legend_events(legend, svg, container, data, add_line_chart, margin, width, height, x_label, y_label, false, false, COLORS)
    add_axes(svg, container, data, margin, width, height, x_label, y_label)
    add_line_chart(svg, container, data, margin, width, height, COLORS)

    # defining buttons actions
    line_button.on("click", () ->
      buttons.selectAll("div[name='type']").each(() ->
        if d3.select(this).property("checked")
          d3.select(this)
            .transition()
            .ease(d3.easeLinear)
            .duration(500)
            .style("background", "gray")
      )
      if d3.select(this).property("checked")
        d3.select(this)
          .transition()
          .ease(d3.easeLinear)
          .duration(500)
          .style("background", "#6699CC")

        svg.selectAll("g")
            .filter(() -> d3.select(this).attr("id") == "chart" || d3.select(this).attr("id") == "axes")
            .transition()
            .duration(500)
            .style("opacity", "0")
            .remove()

        data_to_draw = []
        legend.selectAll("div")
                .filter(() -> +d3.select(this).attr("active"))
                .each(() -> data_to_draw.push(data[+d3.select(this).attr("number")]))

        add_legend_events(legend, svg, container, data, add_line_chart, margin, width, height, x_label, y_label, false, false, COLORS)
        add_axes(svg, container, data_to_draw, margin, width, height, x_label, y_label)
        add_line_chart(svg, container, data_to_draw, margin, width, height, COLORS)       
    )

    log_button.on("click", () ->
      buttons.selectAll("div[name='type']").each(() ->
        if d3.select(this).property("checked")
          d3.select(this)
            .transition()
            .ease(d3.easeLinear)
            .duration(500)
            .style("background", "gray")
      )
      if d3.select(this).property("checked")
        temp = []
        for x, i in data
          temp.push({})
          temp[i].name = x.name
          temp[i].color = x.color
          temp[i].data = []
          for y in x.data
            temp[i].data.push([y[0], y[1]])

        d3.select(this)
          .transition()
          .ease(d3.easeLinear)
          .duration(500)
          .style("background", "#6699CC")

        for x in temp
          x.data = x.data.map((d) -> [d[0], Math.log(1 + d[1])])

        console.log(temp)
        svg.selectAll("g")
            .filter(() -> d3.select(this).attr("id") == "chart" || d3.select(this).attr("id") == "axes")
            .transition()
            .duration(500)
            .style("opacity", "0")
            .remove()

        data_to_draw = []
        legend.selectAll("div")
                .filter(() -> +d3.select(this).attr("active"))
                .each(() -> data_to_draw.push(temp[+d3.select(this).attr("number")]))

        add_legend_events(legend, svg, container, temp, add_line_chart, margin, width, height, x_label, "Логарифм", false, false, COLORS)
        add_axes(svg, container, data_to_draw, margin, width, height, x_label, "Логарифм")
        add_line_chart(svg, container, data_to_draw, margin, width, height, COLORS)       
    )

    if (!is_performance)
      bar_button.on("click", () ->
        buttons.selectAll("div[name='type']").each(() ->
          if d3.select(this).property("checked")
            d3.select(this)
              .transition()
              .ease(d3.easeLinear)
              .duration(500)
              .style("background", "gray")
        )
        if d3.select(this).property("checked")
          temp = []
          for x, i in data
            temp.push({})
            temp[i].name = x.name
            temp[i].color = x.color
            temp[i].data = []
            for y in x.data
              temp[i].data.push([y[0], y[1]])

          d3.select(this)
            .transition()
            .ease(d3.easeLinear)
            .duration(500)
            .style("background", "#6699CC")

          svg.selectAll("g")
              .filter(() -> d3.select(this).attr("id") == "chart" || d3.select(this).attr("id") == "axes")
              .transition()
              .duration(500)
              .style("opacity", "0")
              .remove()

          data_to_draw = []
          legend.selectAll("div")
                  .filter(() -> +d3.select(this).attr("active"))
                  .each(() -> data_to_draw.push(temp[+d3.select(this).attr("number")]))

          bar_data = [{"data" : []}]
          for i in [0..data_to_draw[0].data.length - 1]
            bar_data[0].data.push([data[0].data[i][0], 0])
            for j in [0..data_to_draw.length - 1]
              bar_data[0].data[i][1] += data_to_draw[j].data[i][1]

          add_legend_events(legend, svg, container, temp, add_bar_chart, margin, width, height, x_label, y_label, true, false, COLORS)
          add_axes(svg, container, bar_data, margin, width, height, x_label, y_label)
          add_bar_chart(svg, container, data_to_draw, margin, width, height, COLORS)
      )

    # table control buttons actions defining
    table_control.selectAll("div").on("click", (d, i) ->
      d3.select(this).property("checked", !d3.select(this).property("checked"))
      mode[i] = d3.select(this).property("checked")
      if d3.select(this).property("checked")
        d3.select(this)
          .transition()
          .ease(d3.easeLinear)
          .duration(500)
          .style("background", "#6699CC")
      else
        d3.select(this)
          .transition()
          .ease(d3.easeLinear)
          .duration(500)
          .style("background", "gray")
    )

    table_control.on("click", () ->
      table.selectAll("td")
            .filter(() -> d3.select(this).attr("class") != "fit")
            .each(() ->
              elem = d3.select(this)
              i = +elem.attr("i")
              j = +elem.attr("j")
              val = +elem.attr("value")
              find_j = j
              if !(j % 2) then find_j = j + 1
              next = table.selectAll("td").filter(() -> +d3.select(this).attr("i") == i and +d3.select(this).attr("j") == find_j)
              find_i = i
              if i != 1 then find_i = i - 1
              pred = table.selectAll("td").filter(() -> +d3.select(this).attr("i") == find_i and +d3.select(this).attr("j") == j)
              pred_next = table.selectAll("td").filter(() -> +d3.select(this).attr("i") == find_i and +d3.select(this).attr("j") == find_j)

              perc = Math.round(100  * 100 * val / +next.attr("value")) / 100
              perc_pred = Math.round(100  * 100 * +pred.attr("value") / +pred_next.attr("value")) / 100

              val_pred = +pred.attr("value")
              if mode[0] and mode[1]
                elem.text(val + " (" + perc + "%)")
              else
                if mode[0]
                  elem.text(val)
                if mode[1]
                  if j % 2
                    elem.text(perc + "%")
                  else
                    elem.text(perc + "% --->")

              elem.style("background-color", "white")
              if mode[2] and mode[1]
                if perc > perc_pred
                  elem.style("background-color", "rgba(0, 255, 0, 0.05)")
                if perc < perc_pred 
                  elem.style("background-color", "rgba(255, 0, 0, 0.05)")
              else if mode[2] and mode[0]
                if val > val_pred
                  elem.style("background-color", "rgba(0, 255, 0, 0.05)")
            )
    )

  # adding new onload function
  oldonload = window.onload;
  if typeof(window.onload) != "function"
    window.onload = func
  else
    window.onload = () ->
      if (oldonload)
        oldonload()
      func()
  return 0


# drawing area chart
@draw_area = (data, data_per, src_id, title, x_label, y_label, COLORS = d3.schemeSet1) ->
  for i in [0..data.length - 1]
    data[i].color = i
    data_per[i].color = i
    for j in [0..data[i].data.length - 1]
      s = data[i].data[j][0].split(".")
      data[i].data[j][0] = new Date(+s[2], +s[1] - 1, +s[0])
      data[i].data[j][1] = +data[i].data[j][1]
      s = data_per[i].data[j][0].split(".")
      data_per[i].data[j][0] = new Date(+s[2], +s[1] - 1, +s[0])
      data_per[i].data[j][1] = +data_per[i].data[j][1]

  console.log(data)
  console.log(data_per)

  # defining onload function
  func = () ->
    width = document.getElementById(src_id).offsetWidth
    height = 550

    margin =
      top : 10
      bottom : 80
      right : 10
      left : 80

    container = d3.selectAll("div").filter(() -> d3.select(this).attr("id") == src_id)

    # adding title and legend
    container.append("div")
              .text(title)
              .style("font-family", "Arial")
              .style("font-size", "24px")
              .style("border-radius", "7px")
              .style("font-weight", "500")
              .style("padding", "20px  0px")
              .style("line-height", "25px")
              .style("text-align", "center")
              .style("float", "center")

    legend = add_legend(container, data, COLORS)

    # adding view control buttons
    buttons = container.append("g").attr("id", "buttons")
    log_button = buttons.append("div")
              .text("log")
              .attr("class", "button")
              .style("background", "gray")
              .style("float", "right")
              .attr("name", "type")
              .attr("title", "логарифмическая шкала производительности процессоров")
              .property("checked", "false")
    per_part_bar_button = buttons.append("div")
              .text("3rd bar")
              .attr("class", "button")
              .style("background", "gray")
              .style("float", "right")
              .attr("name", "type")
              .attr("title", "производительность процессоров")
              .property("checked", "false")
    per_bar_button = buttons.append("div")
              .text("2nd bar")
              .attr("class", "button")
              .style("background", "gray")
              .style("float", "right")
              .attr("name", "type")
              .attr("title", "доля производительности")
              .property("checked", "false")
    bar_button = buttons.append("div")
              .text("1st bar")
              .attr("class", "button")
              .style("background", "gray")
              .style("float", "right")
              .attr("name", "type")
              .attr("title", "доля по количеству систем")
              .property("checked", "false")
    pie_button = buttons.append("div")
              .text("pie")
              .attr("class", "button")
              .style("background", "#6699CC")
              .style("float", "right")
              .attr("name", "type")
              .property("checked", "true")

    # adding svg elements
    svg = container.append("svg").attr("style", "width:100%; height:" + height + "px").attr("id", "svg_" + src_id)

    # function for multiple pies via 1 constructor
    add_pies = (svg, container, data, margin, width, height, colors = d3.schemeSet1, measure = y_label) ->
      temp_per = []
      data.forEach((elem) ->
        data_per.forEach((elem_per) ->
          if elem.name == elem_per.name
            temp_per.push(elem_per)
        )
      )
      # making pies
      zoom_func1 = add_pie_chart(svg, container, data, {"top": 10, "bottom": 80, "right": 10 + width / 2, "left": 80}, width, height, COLORS, measure)
      zoom_func2 = add_pie_chart(svg, container, temp_per, {"top": 10, "bottom": 80, "right": 10, "left": 80 + width / 2}, width, height, COLORS, "Производительность, ПФлоп/с")
      # making total zoom function
      zoom_func = () ->
        zoom_func1()
        zoom_func2() 

      zoom = d3.zoom()
            .scaleExtent([1, 1.5])
            .on("zoom", zoom_func)

      if navigator.userAgent.search(/firefox/i) != -1
        zoom.wheelDelta(() ->
              return -d3.event.deltaY * (d3.event.deltaMode ? 120 : 1) / 500
            )

      svg.call(zoom) 

    add_legend_events(legend, svg, container, data, add_pies, margin, width, height, x_label, y_label, false, true, COLORS)
    add_pies(svg, container, data, {"top": 10, "bottom": 80, "right": 10, "left": 80}, width, height)

    # table control processing
    table_control = d3.selectAll("g").filter(() -> d3.select(this).attr("id") == "table_control_" + src_id)
    mode = [true, false, false]
    table = d3.selectAll("table").filter(() -> d3.select(this).attr("id") == "table_" + src_id)
    table_control.selectAll("div").filter(() -> d3.select(this).attr("id") == "0")
                .property("checked", true)
                .each(() -> console.log(d3.select(this).property("checked")))
    table_control.selectAll("div").filter(() -> d3.select(this).attr("id") != "0")
                .property("checked", false)
                .each(() -> console.log(d3.select(this).property("checked")))

    # function for change view actions
    bar_button_action = () ->
      buttons.selectAll("div[name='type']").each(() ->
        if d3.select(this).property("checked")
          d3.select(this)
            .transition()
            .ease(d3.easeLinear)
            .duration(500)
            .style("background", "gray")
      )
      if d3.select(this).text() == "1st bar"
        required_data = data
      else
        required_data = data_per
      if d3.select(this).property("checked")
        temp = []
        for x, i in required_data
          temp.push({})
          temp[i].name = x.name
          temp[i].color = x.color
          temp[i].data = []
          for y, j in x.data
            sum = 100
            if d3.select(this).text() == "2nd bar" || d3.select(this).text() == "1st bar"
              sum = 0
              required_data.forEach((elem) -> sum += elem.data[j][1])
            temp[i].data.push([y[0], y[1] * 100 / sum])

        d3.select(this)
          .transition()
          .ease(d3.easeLinear)
          .duration(500)
          .style("background", "#6699CC")

        svg.selectAll("g")
            .filter(() -> d3.select(this).attr("id") == "chart" || d3.select(this).attr("id") == "axes")
            .transition()
            .duration(500)
            .style("opacity", "0")
            .remove()

        data_to_draw = []
        legend.selectAll("div")
                .filter(() -> +d3.select(this).attr("active"))
                .each(() -> data_to_draw.push(temp[+d3.select(this).attr("number")]))

        bar_data = [{"data" : []}]
        for i in [0..data_to_draw[0].data.length - 1]
          bar_data[0].data.push([data[0].data[i][0], 0])
          for j in [0..data_to_draw.length - 1]
            bar_data[0].data[i][1] += data_to_draw[j].data[i][1]

        add_legend_events(legend, svg, container, temp, add_bar_chart, margin, width, height, x_label, y_label, true, false, COLORS)
        if d3.select(this).text() == "3rd bar"
          add_axes(svg, container, bar_data, margin, width, height, x_label, "Производительность, ПФлоп/с")
        else if d3.select(this).text() == "2nd bar"
          add_axes(svg, container, bar_data, margin, width, height, x_label, "Доля производительности")
        else
          add_axes(svg, container, bar_data, margin, width, height, x_label, y_label)
        add_bar_chart(svg, container, data_to_draw, margin, width, height, COLORS)

    # view control buttons actions defining
    bar_button.on("click", bar_button_action)

    per_bar_button.on("click", bar_button_action)

    per_part_bar_button.on("click", bar_button_action)

    pie_button.on("click", () ->
      buttons.selectAll("div[name='type']").each(() ->
        if d3.select(this).property("checked")
          d3.select(this)
            .transition()
            .ease(d3.easeLinear)
            .duration(500)
            .style("background", "gray")
      )
      if d3.select(this).property("checked")
        temp = []
        for x, i in data
          temp.push({})
          temp[i].name = x.name
          temp[i].color = x.color
          temp[i].data = []
          for y in x.data
            temp[i].data.push([y[0], y[1]])

        d3.select(this)
          .transition()
          .ease(d3.easeLinear)
          .duration(500)
          .style("background", "#6699CC")

        svg.selectAll("g")
            .filter(() -> d3.select(this).attr("id") == "chart" || d3.select(this).attr("id") == "axes")
            .transition()
            .duration(500)
            .style("opacity", "0")
            .remove()

        data_to_draw = []
        legend.selectAll("div")
                .filter(() -> +d3.select(this).attr("active"))
                .each(() -> data_to_draw.push(temp[+d3.select(this).attr("number")]))

        add_legend_events(legend, svg, container, temp, add_pies, margin, width, height, x_label, y_label, false, true, COLORS)
        add_pies(svg, container, data_to_draw, {"top": 10, "bottom": 80, "right": 10, "left": 80}, width, height)
    )

    log_button.on("click", () ->
      buttons.selectAll("div[name='type']").each(() ->
        if d3.select(this).property("checked")
          d3.select(this)
            .transition()
            .ease(d3.easeLinear)
            .duration(500)
            .style("background", "gray")
      )
      if d3.select(this).property("checked")
        temp = []
        for x, i in data_per
          temp.push({})
          temp[i].name = x.name
          temp[i].color = x.color
          temp[i].data = []
          for y in x.data
            temp[i].data.push([y[0], y[1]])

        d3.select(this)
          .transition()
          .ease(d3.easeLinear)
          .duration(500)
          .style("background", "#6699CC")

        for x in temp
          x.data = x.data.map((d) -> [d[0], Math.log(1 + d[1])])

        console.log(temp)
        svg.selectAll("g")
            .filter(() -> d3.select(this).attr("id") == "chart" || d3.select(this).attr("id") == "axes")
            .transition()
            .duration(500)
            .style("opacity", "0")
            .remove()

        data_to_draw = []
        legend.selectAll("div")
                .filter(() -> +d3.select(this).attr("active"))
                .each(() -> data_to_draw.push(temp[+d3.select(this).attr("number")]))

        add_legend_events(legend, svg, container, temp, add_line_chart, margin, width, height, x_label, "Логарифм", false, false, COLORS)
        add_axes(svg, container, data_to_draw, margin, width, height, x_label, "Логарифм")
        add_line_chart(svg, container, data_to_draw, margin, width, height, COLORS)
    )

    table_control.selectAll("div").on("click", (d, i) ->
      console.log("div click")
      d3.select(this).property("checked", !d3.select(this).property("checked"))
      mode[i] = d3.select(this).property("checked")
      if d3.select(this).property("checked")
        d3.select(this)
          .transition()
          .ease(d3.easeLinear)
          .duration(500)
          .style("background", "#6699CC")
      else
        d3.select(this)
          .transition()
          .ease(d3.easeLinear)
          .duration(500)
          .style("background", "gray")
    )

    table_control.on("click", () ->
      console.log("control click")
      table.selectAll("td")
            .filter(() -> d3.select(this).attr("class") != "fit")
            .each(() ->
              elem = d3.select(this)
              i = +elem.attr("i")
              j = +elem.attr("j")

              sum_cnt = 0
              sum_per = 0
              data.forEach((elem) -> sum_cnt += elem.data[i - 1][1])
              data_per.forEach((elem) -> sum_per += elem.data[i - 1][1])
              str_cnt = data[j].data[i - 1][1]
              str_per = data_per[j].data[i - 1][1]
              if mode[2]
                str_cnt = Math.floor(str_cnt * 10000 / sum_cnt) / 100 + "%"
                str_per = Math.floor(str_per * 10000 / sum_per) / 100 + "%"
              if mode[0] && mode[1]
                elem.text(str_cnt + " / " + str_per)
              else if mode[1]
                elem.text(str_per)
              else if mode[0]
                elem.text(str_cnt)
              else
                elem.text("-")
            )
    )  

  # adding new onload function
  oldonload = window.onload;
  if typeof(window.onload) != "function"
    window.onload = func
  else
    window.onload = () ->
      if (oldonload)
        oldonload()
      func()
  return 0

# drawing area chart
@draw_type = (data, src_id, title, x_label, y_label, COLORS = d3.schemeSet1) ->
  for i in [0..data.length - 1]
    data[i].color = i
    for j in [0..data[i].data.length - 1]
      s = data[i].data[j][0].split(".")
      data[i].data[j][0] = new Date(+s[2], +s[1] - 1, +s[0])
      data[i].data[j][1] = +data[i].data[j][1]

  console.log(data)

  # defining onload function
  func = () ->
    width = document.getElementById(src_id).offsetWidth
    height = 550

    margin =
      top : 10
      bottom : 80
      right : 10
      left : 80

    container = d3.selectAll("div").filter(() -> d3.select(this).attr("id") == src_id)

    # adding title and legend
    container.append("div")
              .text(title)
              .style("font-family", "Arial")
              .style("font-size", "24px")
              .style("border-radius", "7px")
              .style("font-weight", "500")
              .style("padding", "20px  0px")
              .style("line-height", "25px")
              .style("text-align", "center")
              .style("float", "center")

    legend = add_legend(container, data, COLORS)

    # adding svg elements
    svg = container.append("svg").attr("style", "width:100%; height:" + height + "px").attr("id", "svg_" + src_id)

    # preparing data for axes
    bar_data = [{"data" : []}]
    for i in [0..data[0].data.length - 1]
      bar_data[0].data.push([data[0].data[i][0], 0])
      for j in [0..data.length - 1]
        bar_data[0].data[i][1] += data[j].data[i][1]

    add_legend_events(legend, svg, container, data, add_bar_chart, margin, width, height, x_label, y_label, true, false, COLORS)
    add_axes(svg, container, bar_data, margin, width, height, x_label, y_label)
    add_bar_chart(svg, container, data, margin, width, height, COLORS)

  # adding new onload function
  oldonload = window.onload;
  if typeof(window.onload) != "function"
    window.onload = func
  else
    window.onload = () ->
      if (oldonload)
        oldonload()
      func()
  return 0

# drawing vendors chart
@draw_vendors = (data, src_id, title, x_label, y_label, COLORS = d3.schemeSet1) ->
  for i in [0..data.length - 1]
    data[i].color = i
    for j in [0..data[i].data.length - 1]
      s = data[i].data[j][0].split(".")
      data[i].data[j][0] = new Date(+s[2], +s[1] - 1, +s[0])
      data[i].data[j][1] = +data[i].data[j][1]

  console.log(data)

  # defining onload function
  func = () ->
    width = document.getElementById(src_id).offsetWidth
    height = 550

    margin =
      top : 10
      bottom : 80
      right : 10
      left : 80

    container = d3.selectAll("div").filter(() -> d3.select(this).attr("id") == src_id)

    # adding title and legend
    container.append("div")
              .text(title)
              .style("font-family", "Arial")
              .style("font-size", "24px")
              .style("border-radius", "7px")
              .style("font-weight", "500")
              .style("padding", "20px  0px")
              .style("line-height", "25px")
              .style("text-align", "center")
              .style("float", "center")

    legend = add_legend(container, data, COLORS)

    # adding view control buttons
    buttons = container.append("g").attr("id", "buttons")
    bar_button = buttons.append("div")
              .text("bar")
              .attr("class", "button")
              .style("background", "gray")
              .style("float", "right")
              .attr("name", "type")
              .attr("title", "доля по количеству систем")
              .property("checked", "false")
    pie_button = buttons.append("div")
              .text("pie")
              .attr("class", "button")
              .style("background", "#6699CC")
              .style("float", "right")
              .attr("name", "type")
              .property("checked", "true")

    # adding svg elements
    svg = container.append("svg").attr("style", "width:100%; height:" + height + "px").attr("id", "svg_" + src_id)

    add_legend_events(legend, svg, container, data, add_pie_chart, margin, width, height, x_label, y_label, false, true, COLORS)
    zoom_func = add_pie_chart(svg, container, data, margin, width, height, COLORS, "Количество систем")
    zoom = d3.zoom()
          .scaleExtent([1, 32])
          .on("zoom", zoom_func)

    if navigator.userAgent.search(/firefox/i) != -1
        zoom.wheelDelta(() ->
              return -d3.event.deltaY * (d3.event.deltaMode ? 120 : 1) / 500
            )

    svg.call(zoom) 

    # view control buttons actions defining
    bar_button.on("click", () ->
      buttons.selectAll("div[name='type']").each(() ->
        if d3.select(this).property("checked")
          d3.select(this)
            .transition()
            .ease(d3.easeLinear)
            .duration(500)
            .style("background", "gray")
      )
      if d3.select(this).property("checked")
        temp = []
        for x, i in data
          temp.push({})
          temp[i].name = x.name
          temp[i].color = x.color
          temp[i].data = []
          for y in x.data
            temp[i].data.push([y[0], y[1]])

        d3.select(this)
          .transition()
          .ease(d3.easeLinear)
          .duration(500)
          .style("background", "#6699CC")

        svg.selectAll("g")
            .filter(() -> d3.select(this).attr("id") == "chart" || d3.select(this).attr("id") == "axes")
            .transition()
            .duration(500)
            .style("opacity", "0")
            .remove()

        data_to_draw = []
        legend.selectAll("div")
                .filter(() -> +d3.select(this).attr("active"))
                .each(() -> data_to_draw.push(temp[+d3.select(this).attr("number")]))

        bar_data = [{"data" : []}]
        for i in [0..data_to_draw[0].data.length - 1]
          bar_data[0].data.push([data[0].data[i][0], 0])
          for j in [0..data_to_draw.length - 1]
            bar_data[0].data[i][1] += data_to_draw[j].data[i][1]

        add_legend_events(legend, svg, container, temp, add_bar_chart, margin, width, height, x_label, y_label, true, false, COLORS)
        add_axes(svg, container, bar_data, margin, width, height, x_label, y_label)
        add_bar_chart(svg, container, data_to_draw, margin, width, height, COLORS)
    )

    pie_button.on("click", () ->
      buttons.selectAll("div[name='type']").each(() ->
        if d3.select(this).property("checked")
          d3.select(this)
            .transition()
            .ease(d3.easeLinear)
            .duration(500)
            .style("background", "gray")
      )
      if d3.select(this).property("checked")
        temp = []
        for x, i in data
          temp.push({})
          temp[i].name = x.name
          temp[i].color = x.color
          temp[i].data = []
          for y in x.data
            temp[i].data.push([y[0], y[1]])

        d3.select(this)
          .transition()
          .ease(d3.easeLinear)
          .duration(500)
          .style("background", "#6699CC")

        svg.selectAll("g")
            .filter(() -> d3.select(this).attr("id") == "chart" || d3.select(this).attr("id") == "axes")
            .transition()
            .duration(500)
            .style("opacity", "0")
            .remove()

        data_to_draw = []
        legend.selectAll("div")
                .filter(() -> +d3.select(this).attr("active"))
                .each(() -> data_to_draw.push(temp[+d3.select(this).attr("number")]))

        add_legend_events(legend, svg, container, temp, add_pie_chart, margin, width, height, x_label, y_label, false, true, COLORS)
        zoom_func = add_pie_chart(svg, container, data_to_draw, margin, width, height, COLORS, "Количество систем")
        zoom = d3.zoom()
              .scaleExtent([1, 1.5])
              .on("zoom", zoom_func)

        svg.call(zoom) 
    )


  # adding new onload function
  oldonload = window.onload;
  if typeof(window.onload) != "function"
    window.onload = func
  else
    window.onload = () ->
      if (oldonload)
        oldonload()
      func()
  return 0

#--------------------
# ADDITIONAL FUCTIONS
#--------------------


# adding chart legend
add_legend = (container, data, colors = d3.schemeSet1) ->
  legend = container.append("g").attr("id", "legend")

  for set, i in data
    legend.append("div")
          .text(data[i].name)
          .attr("active", 1)
          .attr("number", i)
          .attr("class", "button")
          .style("background", colors[i])
          .style("float", "left")

  return legend

# adding chart legend actions
add_legend_events = (legend, svg, container, data, construct, margin, width, height, x_label, y_label, accumulation = false, pie = false, colors = d3.schemeSet1) ->
  legend.selectAll("div")
    .on("click", () ->
          d3.select(this).attr("active", (+d3.select(this).attr("active") + 1) % 2)
            .transition()
            .duration(500)
            .style("background", () -> 
              if +d3.select(this).attr("active")
                return colors[+d3.select(this).attr("number")]
              return "gray"
            )
          temp = []
          legend.selectAll("div")
                .filter(() -> +d3.select(this).attr("active"))
                .each(() -> temp.push(data[+d3.select(this).attr("number")]))

          trs_num = 0
          svg.selectAll("g")
            .filter(() -> d3.select(this).attr("id") == "chart" || d3.select(this).attr("id") == "axes")
            .transition()
            .duration(500)
            .each(() -> trs_num++)
            .style("opacity", "0")
            .remove()
            .on("end", () ->
              trs_num--
              if !trs_num
                axes_data = temp
                if accumulation
                  axes_data = [{"data" : []}]
                  for i in [0..temp[0].data.length - 1]
                    axes_data[0].data.push([data[0].data[i][0], 0])
                    for j in [0..temp.length - 1]
                      axes_data[0].data[i][1] += temp[j].data[i][1]

                if !pie
                  add_axes(svg, container, axes_data, margin, width, height, x_label, y_label)
                  construct(svg, container, temp, margin, width, height, colors)
                else
                  zoom_func = construct(svg, container, temp, margin, width, height, colors)
                  zoom = d3.zoom()
                          .scaleExtent([1, 1.5])
                          .on("zoom", zoom_func)

                  svg.call(zoom)
            )
    )


# adding chart axes
add_axes =  (svg, container, data, margin, width, height, x_label, y_label) ->
  xScale = d3.scaleTime()
            .domain([data[0].data[0][0], data[0].data[data[0].data.length - 1][0]])
            .range([margin.left, width - margin.right])

  temp = []
  dates = data[0].data.map((d) -> d[0])
  for line in data
    temp = temp.concat(line.data.map((d) -> +d[1]))

  yScale = d3.scaleLinear()
              .domain([0, d3.max(temp)])
              .range([height - margin.bottom, margin.top])

  axes = svg.append("g").attr("id", "axes")


  xAxisFun = d3.axisBottom(xScale).tickValues(dates).tickFormat(d3.timeFormat("%m.%y")).tickSize(7)
  xAxis = axes.append("g")
    .attr("id", "x_axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxisFun)

  xAxis.selectAll("text")
      .attr("text-anchor", "end")
      .attr("dx", "-.6em")
      .attr("dy", ".15em")
      .attr("transform", "rotate(-55)")
      .style("font-family", "Arial")
      .style("font-size", "14px")
      .style("font-weight", "500")

  yAxisFun = d3.axisLeft(yScale).tickSize(-width + margin.left + margin.right).tickPadding(8)
  yAxis = axes.append("g")
          .attr("id", "y_axis")
          .attr("transform", "translate(0,0)")
          .call(yAxisFun)

  yAxis.selectAll("text")
      .style("font-family", "Arial")
      .style("font-size", "14px")
      .style("font-weight", "500")

  yAxis.selectAll("line")
      .style("opacity", "0.2")
      .attr("dashoffset", 0)
      .style("stroke-dasharray", "0 0")

  yAxis.selectAll("path")
      .style("opacity", "0.2")

  xAxis.transition()
      .duration(1000)
      .ease(d3.easeLinear)
      .attr("transform", "translate(0," + (height - margin.bottom) + ")")
  yAxis.transition()
      .duration(1000)
      .ease(d3.easeLinear)
      .attr("transform", "translate(" + margin.left + "," + 0 + ")")
      .selectAll("line")
      .attr("dashoffset", 10)
      .style("stroke-dasharray", "7 5")

  axes.append("text")
      .text(x_label)
      .attr("transform", "translate(" + ((width - margin.left - margin.right) / 2 + margin.left) + "," + (height) + ")")
      .style("text-anchor", "middle")
      .style("font-family", "Arial")
      .style("font-size", "16px")
      .style("font-weight", "500")
      .transition()
      .duration(1000)
      .ease(d3.easeLinear)
      .attr("transform", "translate(" + ((width - margin.left - margin.right) / 2 + margin.left) + "," + (height - margin.bottom / 4) + ")")

  axes.append("text")
      .text(y_label)
      .attr("transform", "translate(0," + ((height - margin.top - margin.bottom) / 2 + margin.top) + ") rotate(-90)")
      .style("text-anchor", "middle")
      .style("font-family", "Arial")
      .style("font-size", "16px")
      .style("font-weight", "500")
      .transition()
      .duration(1000)
      .ease(d3.easeLinear)
      .attr("transform", "translate(" + (margin.left / 4) + "," + ((height - margin.top - margin.bottom) / 2 + margin.top) + ") rotate(-90)")

  # adding scale and movement action
  zoom_func = () ->
    newXScale = d3.event.transform.rescaleX(xScale)
    newYScale = d3.event.transform.rescaleY(yScale)

    x_dates = []
    y_domain = [yScale.domain()[1], yScale.domain()[0]]
    bar_max = 0
    data[0].data.forEach((d, i) ->
      if d[0] > newXScale.domain()[0] && d[0] < newXScale.domain()[1]
        x_dates.push(d[0])
        sum = 0
        for set in data
          if set.data[i][1] < y_domain[0]
            y_domain[0] = set.data[i][1]
          if set.data[i][1] > y_domain[1]
            y_domain[1] = set.data[i][1]
          sum += set.data[i][1]
        if sum > bar_max
          bar_max = sum
    )

    newYScale.domain(y_domain)
    newBarYScale = d3.scaleLinear()
                    .domain([0, bar_max])
                    .range([height - margin.bottom, margin.top])

    # update axes
    xAxis.call(xAxisFun.tickValues(x_dates).scale(newXScale))
    yAxis.call(yAxisFun.scale(newYScale))

    xAxis.selectAll("text")
        .attr("text-anchor", "end")
        .attr("dx", "-.6em")
        .attr("dy", ".15em")
        .attr("transform", "rotate(-55)")
        .style("font-family", "Arial")
        .style("font-size", "14px")
        .style("font-weight", "500")
    yAxis.selectAll("text")
        .style("font-family", "Arial")
        .style("font-size", "14px")
        .style("font-weight", "500")
    yAxis.selectAll("line")
        .attr("dashoffset", 10)
        .style("stroke-dasharray", "7 5")
        .style("opacity", "0.2")

    chart = svg.selectAll("g").filter(() -> d3.select(this).attr("id") == "chart")
    chart.selectAll("circle")
          .transition()
          .duration(100)
          .ease(d3.easeLinear)
          .attr("cx", (d) -> newXScale(d[0]))
          .attr("cy", (d) -> newYScale(d[1]))
          .each((d) ->
            if newXScale(d[0]) < margin.left || newXScale(d[0]) > width - margin.right || newYScale(d[1]) < margin.top || newYScale(d[1]) > height - margin.bottom
              d3.select(this).style("opacity", 0)
            else
              d3.select(this).style("opacity", 1)
          )

    line = d3.line()
            .x((d) ->
              if newXScale(d[0]) < margin.left
                return margin.left
              if newXScale(d[0]) > width - margin.right
                return width - margin.right
              return newXScale(d[0])
            )
            .y((d) ->
              if newYScale(d[1]) < margin.top
                return margin.top
              if newYScale(d[1]) > height - margin.bottom
                return height - margin.bottom
              return newYScale(d[1])
            )
            .curve(d3.curveMonotoneX)
    
    # scaling paths
    chart.selectAll("path")
          .style("stroke-dasharray", 0)
          .transition()
          .duration(100)
          .ease(d3.easeLinear)
          .attr("d", (d, i) ->
            path_data = []
            data[i].data.forEach((el, j) ->
              if el[0] >= newXScale.domain()[0] && el[0] <= newXScale.domain()[1] && el[1] >= newYScale.domain()[0] && el[1] <= newYScale.domain()[1]
                path_data.push(el)
              else if j != data[i].data.length - 1 && data[i].data[j + 1][0] >= newXScale.domain()[0] && data[i].data[j + 1][0] <= newXScale.domain()[1] && data[i].data[j + 1][1] >= newYScale.domain()[0] && data[i].data[j + 1][1] <= newYScale.domain()[1]
                path_data.push(el)
              else if j && data[i].data[j - 1][0] >= newXScale.domain()[0] && data[i].data[j - 1][0] <= newXScale.domain()[1] && data[i].data[j - 1][1] >= newYScale.domain()[0] && data[i].data[j - 1][1] <= newYScale.domain()[1]
                path_data.push(el)
            )
            line(path_data)
          )

    # scaling bar chart
    rect_width = width / (x_dates.length * 2)
    chart.selectAll("rect")
          .transition()
          .duration(100)
          .ease(d3.easeLinear)
          .attr("width", rect_width)
          .attr("height", (d) -> newBarYScale(d[0]) - newBarYScale(d[1]))
          .attr("x", (d) -> newXScale(d.data.date) - rect_width / 2)
          .attr("y", (d) -> newBarYScale(d[1]))
          .each((d) ->
            if newXScale(d.data.date) - rect_width / 2 < margin.left || newXScale(d.data.date) + rect_width / 2 > width + margin.right
              d3.select(this).style("opacity", 0)
            else
              d3.select(this).style("opacity", 1)
          )
    add_bar_chart_event(svg, container, newXScale, newBarYScale)

  zoom = d3.zoom()
          .scaleExtent([1, 100])
          .translateExtent([[margin.left, margin.top], [width - margin.right, height - margin.bottom]])
          .extent([[margin.left, margin.top], [width - margin.right, height - margin.bottom]])
          .on("zoom", zoom_func)

  if navigator.userAgent.search(/firefox/i) != -1
        zoom.wheelDelta(() ->
              return -d3.event.deltaY * (d3.event.deltaMode ? 120 : 1) / 500
            )

  svg.call(zoom)
  return axes


# adding line chart
add_line_chart = (svg, container, data, margin, width, height, colors = d3.schemeSet1) ->
  xScale = d3.scaleTime()
            .domain([data[0].data[0][0], data[0].data[data[0].data.length - 1][0]])
            .range([margin.left, width - margin.right])

  temp = []
  for line in data
    temp = temp.concat(line.data.map((d) -> +d[1]))

  yScale = d3.scaleLinear()
              .domain([0, d3.max(temp)])
              .range([height - margin.bottom, margin.top])

  chart = svg.append("g").attr("id", "chart")
  
  line = d3.line()
            .x((d) -> xScale(d[0]))
            .y((d) -> yScale(d[1]))
            .curve(d3.curveMonotoneX)

  for set, i in data
    g = chart.append("g").attr("id", "line" + i)

    path = g.append("path")
      .attr("d", line(set.data))
      .style("stroke", colors[set.color])
      .style("stroke-width", 3)
      .attr("fill", "none")

    g.append("g")
      .attr("id", "circles")
      .selectAll("circle")
      .data(set.data)
      .enter()
      .append("circle")
      .attr("r", 0)
      .attr("color", set.color)
      .attr("cx", (d) -> xScale(d[0]))
      .attr("cy", (d) -> yScale(d[1]))
      .attr("value", (d) -> Math.round(d[1] * 100) / 100)
      .style("fill", colors[set.color])
      .transition()
      .ease(d3.easeElastic)
      .delay((d, i) -> i * 40 + 500)
      .duration(500)
      .attr("r", 5)

    len = path.node().getTotalLength()
    path.attr("stroke-dasharray", len + " " + len)
        .attr("stroke-dashoffset", len)
        .transition()
        .duration(1000)
        .ease(d3.easeLinear)
        .attr("stroke-width", 6)
        .attr("stroke-dashoffset", 0)


  tooltip = container.append("div")
              .attr("id", "tooltip_" + container.attr("id"))
              .style("opacity", 0)
              .style("position", "fixed")
              .style("padding", "2px 10px")
              .style("color", "white")
              .style("border-radius", "7px 7px 0px 7px")
              .style("font-family", "Arial")
              .style("font-size", "14px")
              .style("font-weight", "600")
              .style("float", "right")

  # adding chart elements actions
  svg.selectAll("circle")
    .on("mouseover", () ->
        elem = d3.select(this)
        svg.selectAll("circle")
            .filter(() -> d3.select(this).attr("cx") == elem.attr("cx"))
            .transition()
            .duration(1500)
            .ease(d3.easeElastic)
            .attr("r", 8)
            .style("fill", "white")
            .style("stroke", () -> colors[d3.select(this).attr("color")])
            .style("stroke-width", 3)
        svg.selectAll("circle")
            .filter(() -> d3.select(this).attr("cx") != elem.attr("cx"))
            .transition()
            .duration(1500)
            .ease(d3.easeElastic)
            .attr("r", 3)

        left = document.getElementById("svg_" + container.attr("id")).getBoundingClientRect().left - document.getElementById("tooltip_" + container.attr("id")).offsetWidth - 10
        top = document.getElementById("svg_" + container.attr("id")).getBoundingClientRect().top - document.getElementById("tooltip_" + container.attr("id")).offsetHeight - 10
        tooltip.transition()
              .duration(300)
              .ease(d3.easeElastic)
              .style("opacity", 0.9)
              .style("background", colors[d3.select(this).attr("color")])
              .text(elem.attr("value"))
              .style("left", (+elem.attr("cx") + left) + "px")
              .style("top", (+elem.attr("cy") + top) + "px")
    )
    .on("mouseout", () ->
        xcord = d3.select(this).attr("cx");
        svg.selectAll("circle")
            .transition()
            .duration(2000)
            .ease(d3.easeElastic)
            .attr("r", 5)
            .style("fill", () -> colors[d3.select(this).attr("color")])
            .style("stroke-width", 0)

        tooltip.transition()
            .duration(300)
            .ease(d3.easeElastic)
            .style("opacity", 0)
            .style("top", "0px")
    )
  return chart


# adding bar chart actions by axes scales
add_bar_chart_event = (svg, container, xScale, yScale) ->
  tooltip = container.selectAll("div")
                    .filter(() -> d3.select(this).attr("id") == "tooltip_" + container.attr("id"))

  svg.selectAll("rect")
    .on("mouseover", () ->
        elem = d3.select(this)

        elem.transition()
            .duration(1500)
            .ease(d3.easeElastic)
            .style("stroke-width", 0.05)

        svg.selectAll("rect")
            .filter(() -> d3.select(this).attr("x") != elem.attr("x") || d3.select(this).attr("y") != elem.attr("y"))
            .transition()
            .duration(1500)
            .ease(d3.easeElastic)
            .style("stroke-width", 8)

        left = document.getElementById("svg_" + container.attr("id")).getBoundingClientRect().left - document.getElementById("tooltip_" + container.attr("id")).offsetWidth + 5
        top = document.getElementById("svg_" + container.attr("id")).getBoundingClientRect().top - document.getElementById("tooltip_" + container.attr("id")).offsetHeight + 5
        tooltip.transition()
              .duration(300)
              .ease(d3.easeElastic)
              .style("opacity", 1)
              .style("background", elem.style("fill"))
              .text(elem.attr("value"))
              .style("left", (+elem.attr("x") + left) + "px")
              .style("top", (+elem.attr("y") + top) + "px")
    )
    .on("mouseout", () ->
        xcord = d3.select(this).attr("cx");
        svg.selectAll("rect")
            .transition()
            .duration(2000)
            .ease(d3.easeElastic)
            .style("stroke-width", 2)

        tooltip.transition()
            .duration(300)
            .ease(d3.easeElastic)
            .style("opacity", 0)
            .style("top", "0px")
    )

# drawing bar chart
add_bar_chart = (svg, container, data, margin, width, height, colors = d3.schemeSet1) ->
  months = 1000 * 60 * 60 * 24 * 30 * 4
  right_date = new Date(data[0].data[data[0].data.length - 1][0])
  xScale = d3.scaleTime()
            .domain([data[0].data[0][0] - months, right_date.setTime(right_date.getTime() + months)])
            .range([margin.left, width - margin.right])

  stack = d3.stack()
            .keys([0..data.length - 1])

  # processing data for bar chart
  bar_data = []
  for i in [0..data[0].data.length - 1]
    bar_data.push({"date" : data[0].data[i][0]})
    for j in [0..data.length - 1]
      bar_data[i][j] = data[j].data[i][1]
  
  bar_max = 0
  data[0].data.forEach((d, i) ->
    sum = 0
    for set in data
      sum += set.data[i][1]
    if sum > bar_max
      bar_max = sum
  )

  bar_data = stack(bar_data)
  console.log(bar_data)

  yScale = d3.scaleLinear()
              .domain([0, bar_max])
              .range([height - margin.bottom, margin.top])

  loc_colors = data.map((d) -> d.color)

  chart = svg.append("g").attr("id", "chart")

  rect_width = width / (data[0].data.length * 2)

  chart.selectAll("g")
        .data(bar_data)
        .enter()
        .append("g")
        .style("fill", (d, i) -> colors[loc_colors[i]])
        .selectAll("rect")
        .data((d) -> d)
        .enter()
        .append("rect")
        .attr("value", (d) -> Math.round((d[1] - d[0]) * 100) / 100)
        .attr("x", (d) -> xScale(d.data.date) - rect_width / 2)
        .attr("width", rect_width)
        .attr("rx", 4)
        .attr("ry", 4)
        .attr("y", height - margin.bottom)
        .style("stroke", "white")
        .style("stroke-width", 2)
        .transition()
        .duration(1000)
        .ease(d3.easeLinear)
        .attr("y", (d) -> yScale(d[1]))
        .attr("height", (d) -> yScale(d[0]) - yScale(d[1]))

  tooltip = container.append("div")
                    .attr("id", "tooltip_" + container.attr("id"))
                    .style("opacity", 0)
                    .style("position", "fixed")
                    .style("padding", "2px 10px")
                    .style("color", "white")
                    .style("border-radius", "7px 7px 0px 7px")
                    .style("font-family", "Arial")
                    .style("font-size", "14px")
                    .style("font-weight", "600")
                    .style("float", "right")
                    .style("border-style", "solid")
                    .style("border-width", "3px")
                    .style("border-color", "white")

  add_bar_chart_event(svg, container, xScale, yScale)
  return chart


# drawing pie chart
# WARNING!!! returning zoom function
# not setting zoom automaticly
add_pie_chart = (svg, container, data, margin, width, height, colors = d3.schemeSet1, measure = "Количество систем") ->
  need_arrows = true
  arrows = svg.selectAll("g[id=arrows]")
              .each(() -> need_arrows = !need_arrows)

  chart = svg.append("g").attr("id", "chart")
  if need_arrows
    # making arrows
    triangle = d3.symbol().type(d3.symbolTriangle)
    arrows = chart.append("g")
                  .attr("id", "arrows")
                  .attr("fill", "#6699CC")
    up = arrows.append("path")
              .attr("class", "button")
              .attr("id", "u")
              .attr("d", triangle.size(200))
              .attr("title", "следущая редакция")
    down = arrows.append("path")
                .attr("transform", "translate(0, 15) rotate(60)")
                .attr("class", "button")
                .attr("id", "d")
                .attr("d", triangle.size(200))
                .attr("title", "предыдущая редакция")
  else
    up = arrows.selectAll("path[id=u]")
    down = arrows.selectAll("path[id=d]")

  pie = d3.pie().value((d) -> d.data[d.data.length - 1][1])
  loc_colors = data.map((d) -> d.color)
  outer_radius = Math.min(width - margin.left - margin.right, height - margin.top - margin.bottom) * 0.4
  arc = d3.arc().innerRadius(0.01).outerRadius(outer_radius)
  big_arc = d3.arc().innerRadius(outer_radius / 3).outerRadius(outer_radius * 4 / 3).padAngle(0.04)
  label_arc = d3.arc().innerRadius(0.6 * outer_radius).outerRadius(0.6 * outer_radius)
  tip = d3.arc().innerRadius(outer_radius).outerRadius(outer_radius * 4 / 3).padAngle(0.04)
  center =
    left : (width - margin.left - margin.right) / 2 + margin.left
    top : (height - margin.top - margin.bottom) / 2 + margin.top

  total_value = 0
  arcs = chart.selectAll("g")
              .filter(() -> d3.select(this).attr("id") != "arrows")
              .data(pie(data))
              .enter()
              .append("g")
              .attr("id", "arc")
              .attr("value", (d) -> d.value)
              .attr("redaction", data[0].data.length - 1)
              .each((d) -> total_value += d.value) 
              
  arcs.append("path")
      .attr("value", (d) -> d.value)
      .attr("redaction", data[0].data.length - 1)
      .attr("fill", (d, i) -> colors[loc_colors[i]])
      .attr('transform', "translate(-" + outer_radius + ",-" + outer_radius + ")")
      .transition()
      .duration(1000)
      .ease(d3.easeBackOut)
      .attr('transform', "translate(" + center.left + "," + center.top + ")")
      .attr("d", arc)
      .attrTween("d", (d) ->
          i = d3.interpolate(0, d.endAngle)
          j = d3.interpolate(0, d.startAngle)
          pad = d3.interpolate(d.padAngle, 0)
          return (t) ->
              d.endAngle = i(t)
              d.startAngle = j(t)
              d.padAngle = pad(t)
              return arc(d)
      )

  arcs.append("text")
      .attr("id", "label")
      .attr('transform', "translate(-" + outer_radius + ",-" + outer_radius + ")")
      .transition()
      .duration(1000)
      .ease(d3.easeBackOut)
      .attr("transform", (d) ->
            trans = [label_arc.centroid(d)[0] + center.left, label_arc.centroid(d)[1] + center.top]
            "translate(" + trans + ")"
      )
      .style("font-family", "Arial")
      .style("font-size", "14px")
      .style("font-weight", "600")
      .style("float", "right")
      .style("fill", "white")
      .style("opacity", (d) -> +(Math.round(+d3.select(this.parentNode).attr("value") * 100 / total_value) >= 5))
      .text((d) -> Math.round(+d3.select(this.parentNode).attr("value") * 100 / total_value) + "%")

  tooltip = container.append("div")
                    .attr("id", "tooltip_" + container.attr("id"))
                    .style("opacity", 0)
                    .style("position", "fixed")
                    .style("padding", "2px 10px")
                    .style("color", "white")
                    .style("border-radius", "7px 7px 0px 7px")
                    .style("font-family", "Arial")
                    .style("font-size", "14px")
                    .style("font-weight", "600")
                    .style("float", "right")
                    .style("border-style", "solid")
                    .style("border-width", "3px")
                    .style("border-color", "white")

  init_date = data[0].data[data[0].data.length - 1][0]
  init_date_str = data[0].data.length + "-я редакция (" + (init_date.getMonth() + 1) + "." + init_date.getFullYear() + ")"
  chart.append("text")
        .attr("id", "redaction")
        .attr("transform", "translate(" + center.left + ", " + (height + margin.bottom) + ")")
        .style("background", "white")
        .transition()
        .duration(300)
        .attr("transform", "translate(" + center.left + ", " + (height - margin.bottom / 2) + ")")
        .style("text-anchor", "middle")
        .style("font-family", "Arial")
        .style("font-size", "16px")
        .style("font-weight", "500")
        .text(init_date_str)

  chart.append("text")
        .attr("transform", "translate(" + center.left + ", " + (height + margin.bottom) + ")")
        .style("background", "white")
        .transition()
        .duration(300)
        .attr("transform", "translate(" + center.left + ", " + (height - margin.bottom * 1.2) + ")")
        .style("text-anchor", "middle")
        .style("font-family", "Arial")
        .style("font-size", "16px")
        .style("font-weight", "500")
        .text(measure)

  # adding pie chart actions
  chart.selectAll("g")
    .filter((d) -> d3.select(this).attr("id") == "arc")
    .selectAll("path")
    .on("mouseover", () ->
        elem = d3.select(this)
        rel_pos = []

        elem.transition()
            .duration(300)
            .attr("d", big_arc)
            .each((d) -> rel_pos = tip.centroid(d))

        d3.select(this.parentNode).select("text").style("opacity", 0.0)

        left = document.getElementById("svg_" + container.attr("id")).getBoundingClientRect().left - document.getElementById("tooltip_" + container.attr("id")).offsetWidth + 5
        top = document.getElementById("svg_" + container.attr("id")).getBoundingClientRect().top - document.getElementById("tooltip_" + container.attr("id")).offsetHeight + 5
        tooltip.transition()
              .duration(300)
              .ease(d3.easeElastic)
              .style("opacity", 1)
              .style("background", elem.style("fill"))
              .text(elem.attr("value"))
              .style("left", (rel_pos[0] + left + center.left) + "px")
              .style("top", (rel_pos[1] + top + center.top) + "px")
    )
    .on("mouseout", () ->
        elem = d3.select(this)

        elem.transition()
            .duration(300)
            .attr("d", arc)

        d3.select(this.parentNode).select("text").style("opacity", (d) -> +(Math.round(+d3.select(this.parentNode).attr("value") * 100 / total_value) >= 5))  

        tooltip.transition()
            .duration(300)
            .ease(d3.easeElastic)
            .style("opacity", 0)
            .style("top", "0px")
    )

  # draw redaction function
  draw_redaction = (cur_number) ->
    pie.value((d) -> d.data[cur_number][1])

    total_value = 0
    chart.selectAll("g")
        .filter((d) -> d3.select(this).attr("id") == "arc")
        .data(pie(data))
        .attr("value", (d) -> d.value)
        .attr("redaction", cur_number)
        .each((d) -> total_value += d.value)

    chart.selectAll("path")
        .filter(() -> d3.select(this).attr("id") != "u" && d3.select(this).attr("id") != "d")
        .data(pie(data))
        .attr("value", (d) -> d.value)
        .attr("redaction", cur_number)
        .transition()
        .duration(300)
        .attr("d", arc)

    chart.selectAll("text")
        .filter((d) -> d3.select(this).attr("id") == "label")
        .data(pie(data))
        .attr("transform", (d) ->
              trans = [label_arc.centroid(d)[0] + center.left, label_arc.centroid(d)[1] + center.top]
              "translate(" + trans + ")"
        )
        .style("opacity", (d) -> +(Math.round(+d3.select(this.parentNode).attr("value") * 100 / total_value) >= 5))
        .text((d) -> Math.round(+d3.select(this.parentNode).attr("value") * 100 / total_value) + "%")

    date = data[0].data[cur_number][0]
    date_str = (cur_number + 1) + "-я редакция (" + (date.getMonth() + 1) + "." + date.getFullYear() + ")"
    chart.selectAll("text")
          .filter((d) -> d3.select(this).attr("id") == "redaction")
          .transition()
          .duration(300)
          .text(date_str)

  # arrows appearing
  arrows.attr("transform", "translate(" + (width - 50) + ",-50)")
        .transition()
        .duration(1000)
        .ease(d3.easeBackOut)
        .attr("transform", "translate(" + (width - 50) + "," + (margin.top + 20) + ")")

  # arrows action
  up_fun = () ->
    cur_number = +chart.selectAll("g")
                      .filter((d) -> d3.select(this).attr("id") == "arc")
                      .attr("redaction")
    if cur_number + 1 < data[0].data.length
      draw_redaction(cur_number + 1)
  down_fun = () ->
      cur_number = +chart.selectAll("g")
                        .filter((d) -> d3.select(this).attr("id") == "arc")
                        .attr("redaction")
      if cur_number - 1 > 0
        draw_redaction(cur_number - 1)
    
  if need_arrows
    up.on("click", up_fun)
    down.on("click", down_fun)
  else 
    old_up_fun = up.on("click")
    old_down_fun = down.on("click")
    up.on("click", () ->
      old_up_fun()
      up_fun()
    )
    down.on("click", () ->
      old_down_fun()
      down_fun()
    )
  
  # adiing pie chart zooming
  zoom_func = () ->
    scale_step = 0.5 / (data[0].data.length - 1)
    cur_number = Math.floor((d3.event.transform.k - 1) / scale_step)
    if cur_number != +chart.select("path").attr("redaction")
      draw_redaction(cur_number)

  return zoom_func

$ ->
  $("#add-form-link").click ->	
    onstr = "Показать поля ввода"
    offstr = "Скрыть поля ввода"
    $(this).text(if $(this).text() == onstr then offstr else onstr)
    $("#just-text").toggle()
    $("#form-new_machine").toggle()

  $("#top50_machine_org_id").change ->
    org_id = $(this).val()
    url = "/organizations/#{org_id}/suborgs"
    select = $("#top50_machine_top50_organization_sub_org_id")
    select.select2("val", "")
    select.data("source", url)
    reinit_select2(select)

  reinit_select2 = (el) ->
    select = $(el)
    options = select.find("option")
    $(options[0]).select()  if options.size() is 1
    options =
      placeholder: select2_localization[window.locale]
      allowClear: true

    options.ajax =
      url: select.data("source")
      dataType: "json"
      quietMillis: 100
      data: (term, page) ->
        q: $.trim(term)
        page: page
        per: 10

      results: (data, page) ->
        more = undefined
        more = (page * 10) < data.total
        results: data.records
        more: more
    options.dropdownCssClass = "bigdrop"
    options.initSelection = (element, callback) ->
      if element.val().length > 0
        $.getJSON select.data("source") + "/" + element.val(), {}, (data) ->
          callback
            id: data.id
            text: data.text

    select.select2 options

drawLegend = (svg, colorScale, minLag, maxLag, width, height) ->
  # Размеры легенды
  legendWidth = 300
  legendHeight = 20
  legendX = width / 2 - legendWidth / 2
  legendY = height + 75

  # Добавляем градиент в SVG
  defs = svg.append("defs")
  linearGradient = defs.append("linearGradient")
    .attr("id", "legend-gradient")
    .attr("x1", "0%")
    .attr("x2", "100%")
    .attr("y1", "0%")
    .attr("y2", "0%")

  # Добавляем цветовые остановки (стопы)
  stops = [
    { offset: "0%", color: "#00FF00" }  # Зелёный
    { offset: "20%", color: "#FFFF00" } # Жёлтый
    { offset: "40%", color: "#FFA500" } # Оранжевый
    { offset: "60%", color: "#FF0000" } # Красный
    { offset: "80%", color: "#0000FF" } # Синий
    { offset: "100%", color: "#800080" }# Фиолетовый
  ]

  for stop in stops
    linearGradient.append("stop")
      .attr("offset", stop.offset)
      .attr("stop-color", stop.color)

  # Рисуем прямоугольник с градиентом
  legend = svg.append("g")
    .attr("class", "legend")
    .attr("transform", "translate(#{legendX}, #{legendY})")

  legend.append("rect")
    .attr("width", legendWidth)
    .attr("height", legendHeight)
    .style("fill", "url(#legend-gradient)")

  # Добавляем текст для интервалов (дни)
  legend.append("g")
    .selectAll("text")
    .data([minLag, maxLag])
    .enter()
    .append("text")
    .attr("x", (d, i) -> i * legendWidth) # Левый и правый край
    .attr("y", legendHeight + 15)
    .attr("text-anchor", (d, i) -> if i == 0 then "start" else "end")
    .style("font-size", "12px")
    .text((d) -> d3.format(".2f")(d) + " дн.")

drawHeatmap = (data, containerId, title) ->
  # Очищаем контейнер
  containerSel = d3.select("##{containerId}")
  containerSel.selectAll("*").remove()

  # Уникальные значения редакций и рангов
  editions = Array.from(new Set(data.map((d) -> d.edition))).sort((a, b) -> b - a)
  allRanks = Array.from(new Set(data.map((d) -> d.rank))).filter((r) -> r?).sort((a, b) -> b - a)
  ranks = if allRanks.length > 0 then allRanks else Array.from({ length: getMaxRank() }, (_, i) -> getMaxRank() - i)

  margin = { top: 20, right: 20, bottom: 80, left: 60 }
  edCount = editions.length or 1
  rankCount = ranks.length or 1
  width = Math.max(edCount * HEATMAP_CELL_WIDTH, HEATMAP_MIN_WIDTH)
  height = Math.max(rankCount * HEATMAP_CELL_HEIGHT, HEATMAP_MIN_HEIGHT)

  # Определяем минимальное и максимальное значение lag
  minLag = d3.min(data, (d) -> d.lag)
  maxLag = d3.max(data, (d) -> d.lag)
  if minLag == null or maxLag == null
    minLag = 0
    maxLag = 1

  # Создаём цветовую шкалу
  colorScale = d3.scaleSequential((d3.interpolateRgbBasis(["#00FF00", "#FFFF00", "#FFA500", "#FF0000", "#0000FF", "#800080"])))
    .domain([minLag, maxLag])

  # Шкалы
  x = d3.scaleBand().range([width, 0]).domain(editions).padding(0.05)
  y = d3.scaleBand().range([height, 0]).domain(ranks).padding(0.05)

  # Контейнер SVG
  svg = d3.select("##{containerId}").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom + 70)
    .append("g")
    .attr("transform", "translate(#{margin.left}, #{margin.top})")

  # Оси
  xAxis = svg.append("g")
    .attr("transform", "translate(0, #{height})")
  xAxis.call(d3.axisBottom(x).tickFormat((d) ->
    if typeof editionDatesLag != "undefined" && editionDatesLag && editionDatesLag[d - 1] then editionDatesLag[d - 1] else d
  ))
  xAxis.selectAll("text")
    .attr("transform", "rotate(-45)")
    .style("text-anchor", "end")
  svg.append("text")
    .attr("x", width / 2)
    .attr("y", height + 55)
    .attr("text-anchor", "middle")
    .style("font-size", "16px")
    .text("Редакция")

  svg.append("g").call(d3.axisLeft(y))
  svg.append("text")
    .attr("transform", "rotate(-90)")
    .attr("y", -margin.left + 20)
    .attr("x", -height / 2)
    .attr("text-anchor", "middle")
    .style("font-size", "16px")
    .text("Ранг")

  # Клетки
  cells = svg.selectAll(".cell")
    .data(data.filter((d) -> d.lag != null))
    .enter().append("g")
    .attr("class", "cell")
  cells.append("rect")
    .attr("class", "cell-fill")
    .attr("x", (d) -> x(d.edition))
    .attr("y", (d) -> y(d.rank))
    .attr("width", x.bandwidth())
    .attr("height", y.bandwidth())
    .attr("fill", (d) -> colorScale(d.lag))
    .attr("stroke", "#000")
    .attr("stroke-width", 0.5)
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
  # Подсветка одной логической системы по всем редакциям (machine_key = root по Precedes, иначе machine_id)
  key = (d) -> if d.machine_key? then d.machine_key else d.machine_id
  cells.filter((d) -> key(d) != null)
    .on("mouseenter", (d) ->
      applyMachineHoverHighlight(containerId, d, key)
    )
    .on("mouseleave", ->
      clearMachineHoverHighlight(containerId)
    )
  cells.append("title")
    .text((d) ->
      info = "#{title}\nРедакция: #{d.edition}, Место: #{d.rank}, Отставание: #{d.lag} дн."
      info += heatmapTooltipSystemLine(d)
      info
    )


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
buildLagCsv = (data, inQuarters = false) ->
  editions = Array.from(new Set(data.map((d) -> d.edition))).sort((a, b) -> a - b)
  ranks = Array.from({ length: getMaxRank() }, (_, i) -> i + 1)
  lookup = {}
  data.forEach((d) ->
    if d.lag != null && d.lag != undefined
      val = if inQuarters then d.lag / DAYS_PER_QUARTER else d.lag
      lookup["#{d.edition}-#{d.rank}"] = val
  )
  header = "Место | Редакция," + editions.join(",")
  fmt = (v) -> if v == null or v == undefined then "" else (if inQuarters then (if Math.abs(v) >= 10 then Math.round(v) else d3.format(".2f")(v)) else v)
  rows = ranks.map((rank) ->
    cells = editions.map((ed) -> fmt(lookup["#{ed}-#{rank}"]))
    rank + "," + cells.join(",")
  )
  [header].concat(rows).join("\n")

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
  container = d3.select("##{containerId}")
  return if container.empty()
  container.selectAll("*").remove()
  fullValid = data.filter((d) -> d.lag != null)
  editions = Array.from(new Set(data.map((d) -> d.edition))).sort((a, b) -> b - a)
  allRanks = Array.from(new Set(fullValid.map((d) -> d.rank))).filter((r) -> r?).sort((a, b) -> b - a)
  ranks = if allRanks.length > 0 then allRanks else Array.from({ length: getMaxRank() }, (_, i) -> getMaxRank() - i)

  margin = { top: 20, right: 20, bottom: 80, left: 60 }
  edCount = editions.length or 1
  rankCount = ranks.length or 1
  width = Math.max(edCount * HEATMAP_CELL_WIDTH, HEATMAP_MIN_WIDTH)
  height = Math.max(rankCount * HEATMAP_CELL_HEIGHT, HEATMAP_MIN_HEIGHT)
  flexible = lagFlexibleScale(data, scaleMethod)
  colorScale = flexible.colorScale
  minLag = flexible.minLag
  maxLag = flexible.maxLag
  inQuarters = flexible.inQuarters or false
  x = d3.scaleBand().range([width, 0]).domain(editions).padding(0.05)
  y = d3.scaleBand().range([height, 0]).domain(ranks).padding(0.05)
  svg = container.append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom + 75)
    .append("g")
    .attr("transform", "translate(#{margin.left}, #{margin.top})")
  xAxis = svg.append("g").attr("transform", "translate(0, #{height})")
  xAxis.call(d3.axisBottom(x).tickFormat((d) ->
    if typeof editionDatesLag != "undefined" && editionDatesLag && editionDatesLag[d - 1] then editionDatesLag[d - 1] else d
  ))
  xAxis.selectAll("text").attr("transform", "rotate(-45)").style("text-anchor", "end")
  svg.append("text").attr("x", width / 2).attr("y", height + 55).attr("text-anchor", "middle").style("font-size", "16px").text("Редакция")
  svg.append("g").call(d3.axisLeft(y))
  svg.append("text").attr("transform", "rotate(-90)").attr("y", -margin.left + 20).attr("x", -height / 2).attr("text-anchor", "middle").style("font-size", "16px").text("Ранг")
  validData = data.filter((d) -> d.lag != null)
  cells = svg.selectAll(".cell").data(validData).enter().append("g").attr("class", "cell")
  cells.append("rect").attr("class", "cell-fill")
    .attr("x", (d) -> x(d.edition)).attr("y", (d) -> y(d.rank))
    .attr("width", x.bandwidth()).attr("height", y.bandwidth())
    .attr("fill", (d) -> colorScale(d.lag)).attr("stroke", "#000").attr("stroke-width", 0.5)
  cells.append("rect").attr("class", "cell-contour-sign")
    .attr("x", (d) -> x(d.edition)).attr("y", (d) -> y(d.rank))
    .attr("width", x.bandwidth()).attr("height", y.bandwidth())
    .attr("fill", "none")
    .attr("stroke", (d) -> if d.show_before_announce_contour then "#e91e8c" else "none")
    .attr("stroke-width", 2.5)
  cells.append("rect").attr("class", "cell-hl-outer")
    .attr("x", (d) -> x(d.edition)).attr("y", (d) -> y(d.rank))
    .attr("width", x.bandwidth()).attr("height", y.bandwidth())
    .attr("fill", "none").attr("stroke", "none").attr("stroke-width", 3)
  cells.append("rect").attr("class", "cell-hl-inner")
    .attr("x", (d) -> x(d.edition) + 2).attr("y", (d) -> y(d.rank) + 2)
    .attr("width", x.bandwidth() - 4).attr("height", y.bandwidth() - 4)
    .attr("fill", "none").attr("stroke", "none").attr("stroke-width", 2)
  key = (d) -> if d.machine_key? then d.machine_key else d.machine_id
  cells.filter((d) -> key(d) != null)
    .on("mouseenter", (d) ->
      applyMachineHoverHighlight(containerId, d, key)
    )
    .on("mouseleave", -> clearMachineHoverHighlight(containerId))
  cells.append("title").text((d) ->
    if inQuarters
      q = d.lag / DAYS_PER_QUARTER
      absVal = (if Math.abs(q) >= 10 then Math.round(q) else d3.format(".1f")(Math.abs(q)))
      unit = " кв."
    else
      absVal = Math.abs(d.lag)
      unit = " дн."
    suffix = if d.lag < 0 then " до анонса" else ""
    header = if d.vendor_name and d.component_name then "#{d.vendor_name} #{d.component_name}" else if d.component_name then d.component_name else if d.vendor_name then d.vendor_name else title
    info = "#{header},\nРедакция: #{d.edition}, Место: #{d.rank},\nЗначение: #{absVal}#{unit}#{suffix},"
    info += heatmapTooltipSystemLine(d)
    info
  )
  legendWidth = 300
  legendHeight = 20
  legendX = width / 2 - legendWidth / 2
  legendY = height + 75
  defs = svg.append("defs")
  grad = defs.append("linearGradient").attr("id", gradientId).attr("x1", "0%").attr("x2", "100%").attr("y1", "0%").attr("y2", "0%")
  for i in [0...LAG_RAINBOW.length]
    grad.append("stop").attr("offset", (100 * i / (LAG_RAINBOW.length - 1)) + "%").attr("stop-color", LAG_RAINBOW[i])
  legend = svg.append("g").attr("class", "legend").attr("transform", "translate(#{legendX}, #{legendY})")
  legend.append("rect").attr("width", legendWidth).attr("height", legendHeight).style("fill", "url(##{gradientId})").attr("stroke", "#333").attr("stroke-width", 0.5)
  unitStr = if inQuarters then " кв." else " дн."
  fmt = if inQuarters then lagFormatQuarter else lagFormatDay
  leftLabel = if minLag < 0 then fmt(Math.abs(minLag)) + unitStr + " до анонса" else fmt(minLag) + unitStr
  rightLabel = if maxLag < 0 then fmt(Math.abs(maxLag)) + unitStr + " до анонса" else fmt(maxLag) + unitStr
  leftColor = if minLag < 0 then "#2e7d32" else "#c62828"
  legend.append("text").attr("x", 0).attr("y", legendHeight + 14).attr("text-anchor", "start").style("font-size", "12px").style("fill", leftColor).text(leftLabel)
  legend.append("text").attr("x", legendWidth).attr("y", legendHeight + 14).attr("text-anchor", "end").style("font-size", "12px").style("fill", "#c62828").text(rightLabel)

@updateHeatmaps = (scale, dataSets, containerIds, titles, colorScales, downloadIds, downloadFilenames) ->
  for i in [0...dataSets.length]
    data = transformLagData(dataSets[i], scale)
    drawHeatmap(data, containerIds[i], titles[i])
    if downloadIds and downloadIds[i]
      csv = buildLagCsv(data)
      csvEncoded = encodeURIComponent(csv)
      d3.select("#" + downloadIds[i]).attr("href", "data:text/csv;charset=utf-8," + csvEncoded)
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
  container = d3.select("##{containerId}")
  if container.empty()
    console.error("Container ##{containerId} not found!")
    return
  container.selectAll("*").remove()
  editions = Array.from(new Set(data.map((d) -> d.edition))).sort((a, b) -> b - a)
  allRanks = Array.from(new Set(data.map((d) -> d.rank))).filter((r) -> r?).sort((a, b) -> b - a)
  ranks = if allRanks.length > 0 then allRanks else Array.from({ length: getMaxRank() }, (_, i) -> getMaxRank() - i)

  size = getComponentHeatmapSize(editions, ranks.length)
  width = size.width
  height = size.height
  margin = size.margin
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
  x = d3.scaleBand().range([width, 0]).domain(editions).padding(0.05)
  y = d3.scaleBand().range([height, 0]).domain(ranks).padding(0.05)
  svg = d3.select("##{containerId}").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom + 75)
    .append("g")
    .attr("transform", "translate(#{margin.left}, #{margin.top})")
  xAxisComponent = svg.append("g")
    .attr("transform", "translate(0, #{height})")
  xAxisComponent.call(d3.axisBottom(x).tickFormat((d) ->
    if typeof editionDatesComponent != "undefined" && editionDatesComponent && editionDatesComponent[d - 1] then editionDatesComponent[d - 1] else d
  ))
  xAxisComponent.selectAll("text")
    .attr("transform", "rotate(-45)")
    .style("text-anchor", "end")
  svg.append("text")
    .attr("x", width / 2)
    .attr("y", height + 55)
    .attr("text-anchor", "middle")
    .style("font-size", "16px")
    .text("Редакция")
  svg.append("g").call(d3.axisLeft(y))
  svg.append("text")
    .attr("transform", "rotate(-90)")
    .attr("y", -margin.left + 20)
    .attr("x", -height / 2)
    .attr("text-anchor", "middle")
    .style("font-size", "16px")
    .text("Ранг")
  cells = svg.selectAll(".cell")
    .data(data.filter((d) -> d.lag != null))
    .enter().append("g")
    .attr("class", "cell")
  cells.append("rect")
    .attr("class", "cell-fill")
    .attr("x", (d) -> x(d.edition))
    .attr("y", (d) -> y(d.rank))
    .attr("width", x.bandwidth())
    .attr("height", y.bandwidth())
    .attr("fill", (d) -> colorScale(d.lag))
    .attr("stroke", "#000")
    .attr("stroke-width", 0.5)
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
  key = (d) -> if d.machine_key? then d.machine_key else d.machine_id
  cells.filter((d) -> key(d) != null)
    .on("mouseenter", (d) ->
      applyMachineHoverHighlight(containerId, d, key)
    )
    .on("mouseleave", ->
      clearMachineHoverHighlight(containerId)
    )
  cells.append("title")
    .text((d) ->
      valStr = if tooltipUnit then "#{d.lag} #{tooltipUnit}" else "#{Math.round(d.lag)}"
      header = if d.vendor_name and d.component_name then "#{d.vendor_name} #{d.component_name}" else if d.component_name then d.component_name else if d.vendor_name then d.vendor_name else title
      info = "#{header},\nРедакция: #{d.edition}, Место: #{d.rank},\n#{if tooltipUnit then "Значение: " else "Количество: "}#{valStr},"
      info += heatmapTooltipSystemLine(d)
      info
    )
  drawComponentLegend(svg, width, height, legendSpec)

buildComponentCsv = (data) ->
  editions = Array.from(new Set(data.map((d) -> d.edition))).sort((a, b) -> a - b)
  ranks = Array.from({ length: getMaxRank() }, (_, i) -> i + 1)
  lookup = {}
  data.forEach((d) -> lookup["#{d.edition}-#{d.rank}"] = d.lag)
  header = "Место | Редакция," + editions.join(",")
  rows = ranks.map((rank) ->
    cells = editions.map((ed) ->
      v = lookup["#{ed}-#{rank}"]
      if v == null or v == undefined then "" else (if typeof v == "number" then Math.round(v).toString() else v)
    )
    rank + "," + cells.join(",")
  )
  [header].concat(rows).join("\n")

drawAnnounceToMentionHeatmap = (data, containerId, title, gradientId, unit = "days") ->
  data = data or []
  data = [] unless Array.isArray(data)
  fullData = data
  onlyNewEl = document.getElementById("announce-to-mention-only-new")
  if onlyNewEl and onlyNewEl.checked
    data = data.filter((d) -> d.is_new == true)
  container = d3.select("##{containerId}")
  return if container.empty()
  container.selectAll("*").remove()
  editions = Array.from(new Set(fullData.map((d) -> d.edition))).sort((a, b) -> b - a)
  allRanks = Array.from(new Set(fullData.map((d) -> d.rank))).filter((r) -> r?).sort((a, b) -> b - a)
  ranks = if allRanks.length > 0 then allRanks else Array.from({ length: getMaxRank() }, (_, i) -> getMaxRank() - i)
  size = getComponentHeatmapSize(editions, ranks.length)
  width = size.width
  height = size.height
  margin = size.margin
  fullValid = fullData.filter((d) -> d.lag != null)
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
  x = d3.scaleBand().range([width, 0]).domain(editions).padding(0.05)
  y = d3.scaleBand().range([height, 0]).domain(ranks).padding(0.05)
  validData = data.filter((d) -> d.lag != null)
  svg = container.append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom + 75)
    .append("g")
    .attr("transform", "translate(#{margin.left}, #{margin.top})")
  xAxis = svg.append("g").attr("transform", "translate(0, #{height})")
  xAxis.call(d3.axisBottom(x).tickFormat((d) ->
    if typeof editionDatesComponent != "undefined" && editionDatesComponent && editionDatesComponent[d - 1] then editionDatesComponent[d - 1] else d
  ))
  xAxis.selectAll("text").attr("transform", "rotate(-45)").style("text-anchor", "end")
  svg.append("text").attr("x", width / 2).attr("y", height + 55).attr("text-anchor", "middle").style("font-size", "16px").text("Редакция")
  svg.append("g").call(d3.axisLeft(y))
  svg.append("text").attr("transform", "rotate(-90)").attr("y", -margin.left + 20).attr("x", -height / 2).attr("text-anchor", "middle").style("font-size", "16px").text("Ранг")
  cells = svg.selectAll(".cell").data(validData).enter().append("g").attr("class", "cell")
  cells.append("rect").attr("class", "cell-fill")
    .attr("x", (d) -> x(d.edition)).attr("y", (d) -> y(d.rank))
    .attr("width", x.bandwidth()).attr("height", y.bandwidth())
    .attr("fill", (d) -> cellColor(d)).attr("stroke", "#000").attr("stroke-width", 0.5)
  cells.append("rect").attr("class", "cell-contour-sign")
    .attr("x", (d) -> x(d.edition)).attr("y", (d) -> y(d.rank))
    .attr("width", x.bandwidth()).attr("height", y.bandwidth())
    .attr("fill", "none")
    .attr("stroke", (d) -> if d.show_before_announce_contour then "#e91e8c" else "none")
    .attr("stroke-width", 2.5)
  cells.append("rect").attr("class", "cell-hl-outer")
    .attr("x", (d) -> x(d.edition)).attr("y", (d) -> y(d.rank))
    .attr("width", x.bandwidth()).attr("height", y.bandwidth())
    .attr("fill", "none").attr("stroke", "none").attr("stroke-width", 3)
  cells.append("rect").attr("class", "cell-hl-inner")
    .attr("x", (d) -> x(d.edition) + 2).attr("y", (d) -> y(d.rank) + 2)
    .attr("width", x.bandwidth() - 4).attr("height", y.bandwidth() - 4)
    .attr("fill", "none").attr("stroke", "none").attr("stroke-width", 2)
  key = (d) -> if d.machine_key? then d.machine_key else d.machine_id
  cells.filter((d) -> key(d) != null)
    .on("mouseenter", (d) ->
      applyMachineHoverHighlight(containerId, d, key)
    )
    .on("mouseleave", -> clearMachineHoverHighlight(containerId))
  cells.append("title").text((d) ->
    if inQuarters
      q = d.lag / DAYS_PER_QUARTER
      absVal = (if Math.abs(q) >= 10 then Math.round(q) else d3.format(".1f")(Math.abs(q)))
      unitStr = " кв."
    else
      absVal = Math.abs(d.lag)
      unitStr = " дн."
    suffix = if d.lag < 0 then " до анонса" else " после анонса"
    header = if d.vendor_name and d.component_name then "#{d.vendor_name} #{d.component_name}" else if d.component_name then d.component_name else if d.vendor_name then d.vendor_name else title
    info = "#{header},\nРедакция: #{d.edition}, Место: #{d.rank},\nЗначение: #{absVal}#{unitStr}#{suffix},"
    info += heatmapTooltipSystemLine(d)
    info
  )
  legendWidth = 300
  legendHeight = 20
  legendX = width / 2 - legendWidth / 2
  legendY = height + 75
  defs = svg.append("defs")
  grad = defs.append("linearGradient").attr("id", gradientId).attr("x1", "0%").attr("x2", "100%").attr("y1", "0%").attr("y2", "0%")
  for i in [0...rainbowColors.length]
    grad.append("stop").attr("offset", (100 * i / (rainbowColors.length - 1)) + "%").attr("stop-color", rainbowColors[i])
  legend = svg.append("g").attr("class", "legend").attr("transform", "translate(#{legendX}, #{legendY})")
  legend.append("rect").attr("width", legendWidth).attr("height", legendHeight).style("fill", "url(##{gradientId})").attr("stroke", "#333").attr("stroke-width", 0.5)
  unitStr = if inQuarters then " кв." else " дн."
  fmt = if inQuarters then lagFormatQuarter else ((d) -> Math.round(d).toString())
  leftLabel = if minLag < 0 then fmt(Math.abs(minLag)) + unitStr + " до анонса" else fmt(minLag) + unitStr + " после анонса"
  rightLabel = if maxLag < 0 then fmt(Math.abs(maxLag)) + unitStr + " до анонса" else fmt(maxLag) + unitStr + " после анонса"
  leftColor = if minLag < 0 then "#2e7d32" else "#c62828"
  legend.append("text").attr("x", 0).attr("y", legendHeight + 14).attr("text-anchor", "start").style("font-size", "12px").style("fill", leftColor).text(leftLabel)
  legend.append("text").attr("x", legendWidth).attr("y", legendHeight + 14).attr("text-anchor", "end").style("font-size", "12px").style("fill", "#c62828").text(rightLabel)

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
      d3.select("#" + downloadIds[i]).attr("href", "data:text/csv;charset=utf-8," + encodeURIComponent(csv))
      if downloadFilenames and downloadFilenames[i]
        d3.select("#" + downloadIds[i]).attr("download", downloadFilenames[i])

drawRamHeatmap = (data, containerId, title, scaleMethod) ->
  data = data or []
  data = [] unless Array.isArray(data)
  containerSel = d3.select("##{containerId}")
  containerSel.selectAll("*").remove()
  editions = Array.from(new Set(data.map((d) -> d.edition))).sort((a, b) -> b - a)
  allRanks = Array.from(new Set(data.map((d) -> d.rank))).filter((r) -> r?).sort((a, b) -> b - a)
  ranks = if allRanks.length > 0 then allRanks else Array.from({ length: getMaxRank() }, (_, i) -> getMaxRank() - i)

  # Размеры: 1000×600 при ≤40 редакциях и 50 рангах; иначе масштаб по ячейке 25×12 px; не меньше min для оси и подписи
  margin = { top: 20, right: 20, bottom: 80, left: 60 }
  edCount = editions.length or 1
  rankCount = ranks.length or 1
  width = Math.max(edCount * HEATMAP_CELL_WIDTH, HEATMAP_MIN_WIDTH)
  height = Math.max(rankCount * HEATMAP_CELL_HEIGHT, HEATMAP_MIN_HEIGHT)
  method = (scaleMethod and scaleMethod.toString()) or "quantile"
  flexible = ramFlexibleScale(data, method)
  colorScale = flexible.colorScale
  legendSpec = if flexible.gradient
    { gradient: true, minVal: flexible.minVal, maxVal: flexible.maxVal, gradientId: "ram-grad-" + containerId }
  else
    { labels: flexible.labels }
  x = d3.scaleBand().range([width, 0]).domain(editions).padding(0.05)
  y = d3.scaleBand().range([height, 0]).domain(ranks).padding(0.05)
  svg = d3.select("##{containerId}").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom + 75)
    .append("g")
    .attr("transform", "translate(#{margin.left}, #{margin.top})")
  xAxisRam = svg.append("g")
    .attr("transform", "translate(0, #{height})")
  xAxisRam.call(d3.axisBottom(x).tickFormat((d) ->
    if typeof editionDatesRam != "undefined" && editionDatesRam && editionDatesRam[d - 1] then editionDatesRam[d - 1] else d
  ))
  xAxisRam.selectAll("text")
    .attr("transform", "rotate(-45)")
    .style("text-anchor", "end")
  svg.append("text")
    .attr("x", width / 2)
    .attr("y", height + 55)
    .attr("text-anchor", "middle")
    .style("font-size", "16px")
    .text("Редакция")
  svg.append("g").call(d3.axisLeft(y))
  svg.append("text")
    .attr("transform", "rotate(-90)")
    .attr("y", -margin.left + 20)
    .attr("x", -height / 2)
    .attr("text-anchor", "middle")
    .style("font-size", "16px")
    .text("Ранг")
  cells = svg.selectAll(".cell")
    .data(data.filter((d) -> d.lag != null))
    .enter().append("g")
    .attr("class", "cell")
  
  # Background rectangle (for non-GPU systems or as base)
  cells.append("rect")
    .attr("class", "cell-fill")
    .attr("x", (d) -> x(d.edition))
    .attr("y", (d) -> y(d.rank))
    .attr("width", x.bandwidth())
    .attr("height", y.bandwidth())
    .attr("fill", (d) -> if d.has_gpu then "#f0f0f0" else colorScale(d.lag))
    .attr("stroke", "#000")
    .attr("stroke-width", 0.5)
  
  # Highlight rects (black outer, yellow inner)
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
  
  # Ellipse for GPU systems
  cells.filter((d) -> d.has_gpu)
    .append("ellipse")
    .attr("cx", (d) -> x(d.edition) + x.bandwidth() / 2)
    .attr("cy", (d) -> y(d.rank) + y.bandwidth() / 2)
    .attr("rx", (d) -> x.bandwidth() * 0.4)
    .attr("ry", (d) -> y.bandwidth() * 0.4)
    .attr("fill", (d) -> colorScale(d.lag))
    .attr("stroke", "#000")
    .attr("stroke-width", 0.5)
  
  key = (d) -> if d.machine_key? then d.machine_key else d.machine_id
  cells.filter((d) -> key(d) != null)
    .on("mouseenter", (d) ->
      applyMachineHoverHighlight(containerId, d, key)
    )
    .on("mouseleave", ->
      clearMachineHoverHighlight(containerId)
    )
  cells.append("title")
    .text((d) ->
      info = "#{title}\nРедакция: #{d.edition}, Место: #{d.rank}, ГБ: #{d3.format(".2f")(d.lag)}"
      if d.has_gpu
        info += "\nГибридная система (с GPU)"
      info += heatmapTooltipSystemLine(d)
      info
    )
  drawRamLegend(svg, width, height, legendSpec)

buildRamCsv = (data) ->
  editions = Array.from(new Set(data.map((d) -> d.edition))).sort((a, b) -> a - b)
  ranks = Array.from({ length: getMaxRank() }, (_, i) -> i + 1)
  lookup = {}
  data.forEach((d) -> lookup["#{d.edition}-#{d.rank}"] = d.lag)
  header = "Место | Редакция," + editions.join(",")
  rows = ranks.map((rank) ->
    cells = editions.map((ed) ->
      v = lookup["#{ed}-#{rank}"]
      if v == null or v == undefined then "" else (if typeof v == "number" then v.toFixed(2) else v)
    )
    rank + "," + cells.join(",")
  )
  [header].concat(rows).join("\n")

@updateRamHeatmaps = (dataSets, containerIds, titles, downloadIds, downloadFilenames, scaleMethod) ->
  dataSets = dataSets or []
  for i in [0...dataSets.length]
    data = dataSets[i]
    data = [] if !data or !Array.isArray(data)
    drawRamHeatmap(data, containerIds[i], titles[i], scaleMethod)
    if downloadIds and downloadIds[i]
      csv = buildRamCsv(data)
      d3.select("#" + downloadIds[i]).attr("href", "data:text/csv;charset=utf-8," + encodeURIComponent(csv))
      if downloadFilenames and downloadFilenames[i]
        d3.select("#" + downloadIds[i]).attr("download", downloadFilenames[i])

runStatsWhenReady = (fn) ->
  if document.readyState == "loading"
    document.addEventListener("DOMContentLoaded", fn)
  else
    fn()

runStatsWhenReady ->
  scaleSelector = document.getElementById("scale-selector")
  if scaleSelector and typeof cpuDataLinear != "undefined"
    dataSets = [cpuDataLinear, gpuDataLinear, combinedDataLinear]
    containerIds = ["cpu_heatmap", "gpu_heatmap", "combined_heatmap"]
    downloadIds = ["download_cpu_lag", "download_gpu_lag", "download_combined_lag"]
    downloadFilenames = ["CPU_lag.csv", "GPU_lag.csv", "Combined_lag.csv"]
    titles = ["CPU Отставание", "GPU Отставание", "Общее Отставание min(CPU, GPU)"]
    gradientIds = ["lag-legend-cpu", "lag-legend-gpu", "lag-legend-combined"]
    getFreshestLagScale = () ->
      (document.getElementById("scale-selector") or {}).value or "linear"

    updateLagEditionEndOptions = () ->
      startSel = document.getElementById("lag-edition-start")
      endSel = document.getElementById("lag-edition-end")
      return unless startSel and endSel
      startIdx = parseInt(startSel.selectedIndex)
      for i in [0...endSel.options.length]
        endSel.options[i].hidden = i < startIdx
      if endSel.selectedIndex < startIdx
        endSel.selectedIndex = startIdx

    updateLagEditionStartOptions = () ->
      startSel = document.getElementById("lag-edition-start")
      endSel = document.getElementById("lag-edition-end")
      return unless startSel and endSel
      endIdx = parseInt(endSel.selectedIndex)
      for i in [0...startSel.options.length]
        startSel.options[i].hidden = i > endIdx
      if startSel.selectedIndex > endIdx
        startSel.selectedIndex = endIdx

    updateLagRankEndOptions = () ->
      startSel = document.getElementById("lag-rank-start")
      endSel = document.getElementById("lag-rank-end")
      return unless startSel and endSel
      startIdx = parseInt(startSel.selectedIndex)
      for i in [0...endSel.options.length]
        endSel.options[i].hidden = i < startIdx
      if endSel.selectedIndex < startIdx
        endSel.selectedIndex = startIdx

    updateLagRankStartOptions = () ->
      startSel = document.getElementById("lag-rank-start")
      endSel = document.getElementById("lag-rank-end")
      return unless startSel and endSel
      endIdx = parseInt(endSel.selectedIndex)
      for i in [0...startSel.options.length]
        startSel.options[i].hidden = i > endIdx
      if startSel.selectedIndex > endIdx
        startSel.selectedIndex = endIdx

    updateLagHeatmaps = () ->
      updateLagEditionEndOptions()
      updateLagEditionStartOptions()
      updateLagRankEndOptions()
      updateLagRankStartOptions()
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
      for i in [0...dataSets.length]
        fullData = dataSets[i] or []
        data = fullData.filter((d) ->
          ed = d.edition
          rk = d.rank
          ed? and rk? and ed >= edFrom and ed <= edTo and rk >= rkFrom and rk <= rkTo
        )
        drawFreshestLagHeatmap(data, containerIds[i], titles[i], scaleMethod, gradientIds[i])
        if downloadIds and downloadIds[i]
          csv = buildLagCsv(data, inQuarters)
          d3.select("#" + downloadIds[i]).attr("href", "data:text/csv;charset=utf-8," + encodeURIComponent(csv))
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

  if typeof ramPerCoreData != "undefined"
    ramDataSets = [
      ramPerCoreData || [],
      (if typeof ramPerCpuData != "undefined" then ramPerCpuData else []),
      (if typeof ramPerNodeData != "undefined" then ramPerNodeData else [])
    ]
    ramContainerIds = ["ram_per_core_heatmap", "ram_per_cpu_heatmap", "ram_per_node_heatmap"]
    ramDownloadIds = ["download_ram_per_core", "download_ram_per_cpu", "download_ram_per_node"]
    ramDownloadFilenames = ["RAM_per_core.csv", "RAM_per_cpu.csv", "RAM_per_node.csv"]
    ramTitles = ["RAM на ядро (ГБ)", "RAM на CPU (ГБ)", "RAM на узел (ГБ)"]
    getRamScale = () -> (document.getElementById("scale-selector-ram") or {}).value or "quantile"
    getRamShowHybrid = () ->
      el = document.getElementById("ram-show-hybrid")
      el and el.checked
    getRamRanges = () ->
      parseVal = (id, fallback) ->
        el = document.getElementById(id)
        v = parseInt(el?.value)
        if isNaN(v) then fallback else v
      maxEdition = (editionDatesRam || []).length or 1
      es = parseVal("ram-edition-start", 1)
      ee = parseVal("ram-edition-end", maxEdition)
      rs = parseVal("ram-rank-start", 1)
      re = parseVal("ram-rank-end", getMaxRank())
      if es > ee then [es, ee] = [ee, es]
      if rs > re then [rs, re] = [re, rs]
      {
        editionStart: Math.max(1, es)
        editionEnd: Math.max(1, Math.min(maxEdition, ee))
        rankStart: Math.max(1, rs)
        rankEnd: Math.min(getMaxRank(), re)
      }
    filterByRangesRam = (data, ranges) ->
      (data or []).filter((d) ->
        ed = d.edition
        rk = d.rank
        ed? and rk? and ed >= ranges.editionStart and ed <= ranges.editionEnd and rk >= ranges.rankStart and rk <= ranges.rankEnd
      )
    updateRamAll = () ->
      showHybrid = getRamShowHybrid()
      ranges = getRamRanges()
      baseSets = if showHybrid
        ramDataSets
      else
        ramDataSets.map((data) -> (data or []).filter((d) -> !d.has_gpu))
      filtered = baseSets.map((data) -> filterByRangesRam(data, ranges))
      updateRamHeatmaps(filtered, ramContainerIds, ramTitles, ramDownloadIds, ramDownloadFilenames, getRamScale())
    updateRamAll()
    ramScaleEl = document.getElementById("scale-selector-ram")
    if ramScaleEl
      ramScaleEl.addEventListener("change", updateRamAll)
    ramShowHybridEl = document.getElementById("ram-show-hybrid")
    if ramShowHybridEl
      ramShowHybridEl.addEventListener("change", updateRamAll)
    ["ram-edition-start","ram-edition-end","ram-rank-start","ram-rank-end"].forEach((id) ->
      el = document.getElementById(id)
      if el
        el.addEventListener("change", updateRamAll)
    )

  if typeof cpuTotalData != "undefined"
    getComponentMetric = () -> (document.getElementById("metric-selector-component") or {}).value or "total"
    getComponentScale = () -> (document.getElementById("scale-selector-component") or {}).value or "quantile"
    getFreshestIncludeGpu = () ->
      el = document.getElementById("freshest-include-gpu")
      el and el.checked
    getComponentRanges = () ->
      parseVal = (id, fallback) ->
        el = document.getElementById(id)
        v = parseInt(el?.value)
        if isNaN(v) then fallback else v
      maxEdition = (editionDatesComponent || []).length or 1
      es = parseVal("component-edition-start", 1)
      ee = parseVal("component-edition-end", maxEdition)
      rs = parseVal("component-rank-start", 1)
      re = parseVal("component-rank-end", getMaxRank())
      if es > ee then [es, ee] = [ee, es]
      if rs > re then [rs, re] = [re, rs]
      {
        editionStart: Math.max(1, es)
        editionEnd: Math.max(1, Math.min(maxEdition, ee))
        rankStart: Math.max(1, rs)
        rankEnd: Math.min(getMaxRank(), re)
      }

    filterByRangesComponent = (data, ranges) ->
      (data or []).filter((d) ->
        ed = d.edition
        rk = d.rank
        ed? and rk? and ed >= ranges.editionStart and ed <= ranges.editionEnd and rk >= ranges.rankStart and rk <= ranges.rankEnd
      )

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
        componentTitles = ["CPU: всего", "GPU: всего", "Самые свежие компоненты: всего", "Ядра: всего", "GPU ядра (мультипроцессорные блоки): всего", "GPU микроядра (CUDA): всего"]
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
        componentTitles = ["CPU: на узел", "GPU: на узел", "Самые свежие компоненты: на узел", "Ядра: на узел", "GPU ядра (мультипроцессорные блоки): на узел", "GPU микроядра (CUDA): на узел"]
        componentDownloadFilenames = ["CPU_per_node.csv", "GPU_per_node.csv", "Freshest_per_node.csv", "Cores_per_node.csv", "GPU_cores_per_node.csv", "GPU_microcores_per_node.csv"]
      componentDataSets = baseSets.map((data) -> filterByRangesComponent(data, ranges))
      componentContainerIds = ["cpu_component_heatmap", "gpu_component_heatmap", "freshest_component_heatmap", "cores_component_heatmap", "gpu_cores_component_heatmap", "gpu_microcores_only_component_heatmap"]
      componentDownloadIds = ["download_cpu_component", "download_gpu_component", "download_freshest_component", "download_cores_component", "download_gpu_cores_component", "download_gpu_microcores_only_component"]
      updateComponentHeatmaps(componentDataSets, componentContainerIds, componentTitles, componentDownloadIds, componentDownloadFilenames, scaleMethod)
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
    ["component-edition-start","component-edition-end","component-rank-start","component-rank-end"].forEach((id) ->
      el = document.getElementById(id)
      if el
        el.addEventListener("change", updateComponentAll)
    )

  # ---------- freshest_comp_stats: heatmaps — same pattern as freshest_components_lag (option constraining + filter + redraw) ----------
  if typeof freshestCpuQuantityData != "undefined"
    getFreshestQuantityScale = () -> (document.getElementById("scale-selector-freshest-quantity") or {}).value or "quantile"
    updateFreshestHeatmapEditionEndOptions = () ->
      startSel = document.getElementById("freshest-heatmap-edition-start")
      endSel = document.getElementById("freshest-heatmap-edition-end")
      return unless startSel and endSel
      startIdx = parseInt(startSel.selectedIndex)
      for i in [0...endSel.options.length]
        endSel.options[i].hidden = i < startIdx
      if endSel.selectedIndex < startIdx
        endSel.selectedIndex = startIdx
    updateFreshestHeatmapEditionStartOptions = () ->
      startSel = document.getElementById("freshest-heatmap-edition-start")
      endSel = document.getElementById("freshest-heatmap-edition-end")
      return unless startSel and endSel
      endIdx = parseInt(endSel.selectedIndex)
      for i in [0...startSel.options.length]
        startSel.options[i].hidden = i > endIdx
      if startSel.selectedIndex > endIdx
        startSel.selectedIndex = endIdx
    updateFreshestHeatmapRankEndOptions = () ->
      startSel = document.getElementById("freshest-heatmap-rank-start")
      endSel = document.getElementById("freshest-heatmap-rank-end")
      return unless startSel and endSel
      startIdx = parseInt(startSel.selectedIndex)
      for i in [0...endSel.options.length]
        endSel.options[i].hidden = i < startIdx
      if endSel.selectedIndex < startIdx
        endSel.selectedIndex = startIdx
    updateFreshestHeatmapRankStartOptions = () ->
      startSel = document.getElementById("freshest-heatmap-rank-start")
      endSel = document.getElementById("freshest-heatmap-rank-end")
      return unless startSel and endSel
      endIdx = parseInt(endSel.selectedIndex)
      for i in [0...startSel.options.length]
        startSel.options[i].hidden = i > endIdx
      if startSel.selectedIndex > endIdx
        startSel.selectedIndex = endIdx
    filterByEditionAndRank = (data, ranges) ->
      (data or []).filter((d) ->
        ed = d.edition
        rk = d.rank
        ed? and rk? and ed >= ranges.editionStart and ed <= ranges.editionEnd and rk >= ranges.rankStart and rk <= ranges.rankEnd
      )
    updateFreshestQuantityHeatmaps = () ->
      updateFreshestHeatmapEditionEndOptions()
      updateFreshestHeatmapEditionStartOptions()
      updateFreshestHeatmapRankEndOptions()
      updateFreshestHeatmapRankStartOptions()
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
      dataCpu = filterByEditionAndRank(freshestCpuQuantityData or [], ranges)
      dataGpu = filterByEditionAndRank(freshestGpuQuantityData or [], ranges)
      scaleMethod = getFreshestQuantityScale()
      drawComponentHeatmap(dataCpu, "freshest_cpu_quantity_heatmap", "Самые свежие CPU: количество", scaleMethod)
      drawComponentHeatmap(dataGpu, "freshest_gpu_quantity_heatmap", "Самые свежие GPU: количество", scaleMethod)
      if document.getElementById("download_freshest_cpu_quantity")
        csvCpu = buildComponentCsv(dataCpu)
        d3.select("#download_freshest_cpu_quantity").attr("href", "data:text/csv;charset=utf-8," + encodeURIComponent(csvCpu))
      if document.getElementById("download_freshest_gpu_quantity")
        csvGpu = buildComponentCsv(dataGpu)
        d3.select("#download_freshest_gpu_quantity").attr("href", "data:text/csv;charset=utf-8," + encodeURIComponent(csvGpu))
      if typeof announceToMentionCpuData != "undefined"
        dataAnnounceCpu = filterByEditionAndRank(announceToMentionCpuData or [], ranges)
        dataAnnounceGpu = filterByEditionAndRank(announceToMentionGpuData or [], ranges)
        announceUnit = (document.getElementById("announce-to-mention-unit") or {}).value or "days"
        drawAnnounceToMentionHeatmap(dataAnnounceCpu, "announce_to_mention_cpu_heatmap", "CPU: разница между анонсом и первым упоминанием", "announce-to-mention-legend-cpu", announceUnit)
        drawAnnounceToMentionHeatmap(dataAnnounceGpu, "announce_to_mention_gpu_heatmap", "GPU: разница между анонсом и первым упоминанием", "announce-to-mention-legend-gpu", announceUnit)
        inQuarters = (announceUnit == "quarters")
        if document.getElementById("download_announce_to_mention_cpu")
          csvCpu = if inQuarters then buildLagCsv(dataAnnounceCpu, true) else buildComponentCsv(dataAnnounceCpu)
          d3.select("#download_announce_to_mention_cpu").attr("href", "data:text/csv;charset=utf-8," + encodeURIComponent(csvCpu)).attr("download", if inQuarters then "CPU_announce_to_mention_quarters.csv" else "CPU_announce_to_mention_days.csv")
        if document.getElementById("download_announce_to_mention_gpu")
          csvGpu = if inQuarters then buildLagCsv(dataAnnounceGpu, true) else buildComponentCsv(dataAnnounceGpu)
          d3.select("#download_announce_to_mention_gpu").attr("href", "data:text/csv;charset=utf-8," + encodeURIComponent(csvGpu)).attr("download", if inQuarters then "GPU_announce_to_mention_quarters.csv" else "GPU_announce_to_mention_days.csv")
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
    freshestHeatmapSelIds.forEach((id) ->
      el = document.getElementById(id)
      if el
        el.addEventListener("change", updateFreshestQuantityHeatmaps)
    )

  # freshest_comp_stats: bar charts — separate edition dropdowns (not heatmaps), filter + scroll + sticky Y
  runStatsWhenReady ->
    fqStartSel = document.getElementById("freshest-charts-edition-start")
    fqEndSel   = document.getElementById("freshest-charts-edition-end")
    fqChartEl  = document.getElementById("chart_freshest_quantity_systems")
    return unless fqStartSel and fqEndSel and fqChartEl and typeof window.editionDatesFreshestQuantity != "undefined"
    fqCharts = [
      { id: "chart_freshest_quantity_systems", dataKey: "chartDataFreshestQuantity", title: "Количество систем с новыми компонентами по редакциям", xLabel: "Дата (ММ.ГГ)", yLabel: "Количество систем" }
      { id: "chart_freshest_quantity_models", dataKey: "chartDataFreshestQuantityModels", title: "Количество новых моделей компонент по редакциям", xLabel: "Дата (ММ.ГГ)", yLabel: "Количество моделей" }
      { id: "chart_freshest_quantity_components", dataKey: "chartDataFreshestQuantityComponents", title: "Количество новых компонент по редакциям", xLabel: "Дата (ММ.ГГ)", yLabel: "Количество компонентов" }
      { id: "chart_freshest_quantity_pct_all", dataKey: "chartDataFreshestQuantityPctAll", title: "Доля новых компонент (от компонент всех систем), %", xLabel: "Дата (ММ.ГГ)", yLabel: "% от всех компонентов" }
      { id: "chart_freshest_quantity_pct_new_systems", dataKey: "chartDataFreshestQuantityPctNewSystems", title: "Доля новых компонент (от компонент систем с новыми), %", xLabel: "Дата (ММ.ГГ)", yLabel: "% от всех компонентов" }
      { id: "chart_freshest_quantity_rpeak_pct", dataKey: "chartDataFreshestQuantityRpeakPct", title: "Процент Rpeak (от общего) систем с новыми компонентами", xLabel: "Дата (ММ.ГГ)", yLabel: "% Rpeak" }
      { id: "chart_freshest_quantity_rmax_pct", dataKey: "chartDataFreshestQuantityRmaxPct", title: "Процент Rmax (от общего) систем с новыми компонентами", xLabel: "Дата (ММ.ГГ)", yLabel: "% Rmax" }
    ]
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
    sliceFqChartData = (chartData, edFrom, edTo) ->
      return [] unless chartData and chartData.length > 0
      chartData.map((s) ->
        arr = (s.data or []).slice(edFrom - 1, edTo)
        { name: s.name, color: s.color, data: arr.map((p) -> [p[0], p[1]]) }
      )
    updateFqBarCharts = () ->
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
      fqCharts.forEach((cfg) ->
        el = document.getElementById(cfg.id)
        if !el then return
        el.style.minWidth = minChartWidth + "px"
        data = window[cfg.dataKey]
        if !data or !data.length or !data[0].data then return
        filtered = sliceFqChartData(data, edFrom, edTo)
        if filtered.length > 0 and filtered[0].data and filtered[0].data.length > 0
          draw_new_vs_upgraded_new(filtered, cfg.id, cfg.title, cfg.xLabel, cfg.yLabel)
      )
    updateFqBarCharts()
    fqStartSel.addEventListener("change", updateFqBarCharts)
    fqEndSel.addEventListener("change", updateFqBarCharts)

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
        drawMatrix(filteredMatrix, "matrix_chart", "Изменение систем в рейтинге")
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
  # Run in a separate ready pass so inline scripts (chartData + initial draw) have run
  runStatsWhenReady ->
    newUpgStartSel = document.getElementById("new-upg-edition-start")
    newUpgEndSel   = document.getElementById("new-upg-edition-end")
    newUpgChartEl  = document.getElementById("chart_new_vs_upgraded")
    return unless newUpgStartSel and newUpgEndSel and newUpgChartEl and typeof window.chartData != "undefined"
    updateNewUpgEditionEndOptions = () ->
      return unless newUpgEndSel
      for i in [0...newUpgEndSel.options.length]
        newUpgEndSel.options[i].hidden = false
    updateNewUpgEditionStartOptions = () ->
      return unless newUpgStartSel and newUpgEndSel
      endIdx = parseInt(newUpgEndSel.selectedIndex)
      for i in [0...newUpgStartSel.options.length]
        newUpgStartSel.options[i].hidden = i < endIdx
      if newUpgStartSel.selectedIndex < endIdx
        newUpgStartSel.selectedIndex = endIdx
    sliceNewUpgChartData = (chartData, edFrom, edTo) ->
      return [] unless chartData and chartData.length > 0
      chartData.map((s) ->
        arr = (s.data or []).slice(edFrom - 1, edTo)
        { name: s.name, color: s.color, data: arr.map((p) -> [p[0], p[1]]) }
      )
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
      filteredMain = sliceNewUpgChartData(window.chartData, edFrom, edTo)
      filteredRpeak = sliceNewUpgChartData(window.chartDataRpeakPct, edFrom, edTo)
      filteredRmax   = sliceNewUpgChartData(window.chartDataRmaxPct, edFrom, edTo)
      numPoints = (filteredMain[0]?.data?.length) or 0
      minChartWidth = Math.max(1000, numPoints * 40)
      newUpgChartIds = ["chart_new_vs_upgraded", "chart_new_vs_upgraded_rpeak_pct", "chart_new_vs_upgraded_rmax_pct"]
      newUpgChartIds.forEach((id) ->
        el = document.getElementById(id)
        if el then el.style.minWidth = minChartWidth + "px"
      )
      if filteredMain.length > 0 and filteredMain[0].data and filteredMain[0].data.length > 0
        draw_new_vs_upgraded_new(filteredMain, "chart_new_vs_upgraded", "Новые и обновлённые системы по редакциям", "Дата (ММ.ГГ)", "Количество систем")
      if filteredRpeak.length > 0 and filteredRpeak[0].data and filteredRpeak[0].data.length > 0
        draw_new_vs_upgraded_new(filteredRpeak, "chart_new_vs_upgraded_rpeak_pct", "Процент Rpeak (от общего) новых и обновлённых систем", "Дата (ММ.ГГ)", "% Rpeak")
      if filteredRmax.length > 0 and filteredRmax[0].data and filteredRmax[0].data.length > 0
        draw_new_vs_upgraded_new(filteredRmax, "chart_new_vs_upgraded_rmax_pct", "Процент Rmax (от общего) новых и обновлённых систем", "Дата (ММ.ГГ)", "% Rmax")
      rows = document.querySelectorAll("table.table tbody tr[data-edition-index]")
      for i in [0...rows.length]
        idx = parseInt(rows[i].getAttribute("data-edition-index"), 10)
        rows[i].style.display = (idx >= edFrom and idx <= edTo) ? "" : "none"
      summary = window.ratingsSummaryNewUpg or []
      filteredSummary = summary.filter((r) -> r.edition_index >= edFrom and r.edition_index <= edTo)
      header = "Редакция,Новые машины,Обновлённые машины,Новые и обновлённые машины,% Новых машин,% Обновлённых машин,% Новых и обновлённых машин,% Rpeak новых машин,% Rmax новых машин,% Rpeak обновлённых машин,% Rmax обновлённых машин,% Rpeak новых и обновлённых машин,% Rmax новых и обновлённых машин"
      csvLines = [header]
      escapeCsvField = (v) ->
        s = String(v)
        if /[,"\n\r]/.test(s) then "\"" + s.replace(/\"/g, "\"\"") + "\"" else s
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
    topContainer.append("div")
              .text(title)
              .style("font-family", "Arial")
              .style("font-size", "24px")
              .style("font-weight", "500")
              .style("text-align", "center")
              .style("margin-bottom", "20px")

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
      svg.append("text")
         .attr("transform", "rotate(-90)")
         .attr("y", margin.left - 70)
         .attr("x", 0 - (height / 2))
         .attr("dy", "1em")
         .style("text-anchor", "middle")
         .style("font-family", "Arial")
         .style("font-size", "14px")
         .text(y_label)

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


# "YYYY-MM" -> "MM.YY" for list_upg x-axis
formatEditionDate = (s) ->
  return s unless s
  parts = String(s).split("-")
  if parts.length >= 2 then parts[1] + "." + (if parts[0].length >= 2 then parts[0].slice(-2) else parts[0]) else s

@drawMatrix = (data, containerId, title) ->
  # Очищаем контейнер
  containerSel = d3.select("##{containerId}")
  containerSel.selectAll("*").remove()

  # Уникальные значения для редакций (даты)
  editions = Array.from(new Set(data.map((d) -> d.edition))).sort()
  ranks = Array.from(new Set(data.map((d) -> d.rank))).sort((a, b) -> a - b)

  margin = { top: 20, right: 20, bottom: 80, left: 70 }
  edCount = editions.length or 1
  rankCount = ranks.length or 1
  width = Math.max(edCount * HEATMAP_CELL_WIDTH, HEATMAP_MIN_WIDTH)
  height = Math.max(rankCount * HEATMAP_CELL_HEIGHT, HEATMAP_MIN_HEIGHT)

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

  # Шкалы (x = дата редакции)
  x = d3.scaleBand().range([0, width]).domain(editions).padding(0.05)
  y = d3.scaleBand().range([0, height]).domain(ranks).padding(0.05)

  # Контейнер
  container = d3.select("##{containerId}")

  # Заголовок
  container.append("div")
    .text(title)
    .style("font-family", "Arial")
    .style("font-size", "24px")
    .style("font-weight", "500")
    .style("text-align", "center")
    .style("margin-bottom", "20px")

  # Кнопки для фильтрации
  activeFilters = { new: true, updated: true, moved_up: true, moved_down: true }
  buttons = container.append("div").style("margin-bottom", "10px")

  Object.keys(statusColors).forEach((status) ->
    buttons.append("button")
      .text(statusLabels[status])  # Используем русские названия
      .style("background-color", statusColors[status])
      .style("color", "white")
      .style("border", "2px solid #000")
      .style("border-radius", "5px")
      .style("padding", "5px 10px")
      .style("margin-right", "10px")
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

          # Проверяем активные статусы
          leftActive = d.new_upd_status and activeFilters[d.new_upd_status]
          rightActive = d.pos_status and activeFilters[d.pos_status]

          cellWidth = x.bandwidth()
          cellHeight = y.bandwidth()

          if (leftActive) and (rightActive)
            # Оба статуса активны: клетка разделена
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
            # Только левый статус активен: закрасить всю клетку в левый цвет
            cellGroup.select(".left-half")
              .attr("x", x(d.edition))
              .attr("width", cellWidth)
              .attr("fill", statusColors[d.new_upd_status])
              .attr("visibility", "visible")

            cellGroup.select(".right-half")
              .attr("visibility", "hidden")
          else if rightActive
            # Только правый статус активен: закрасить всю клетку в правый цвет
            cellGroup.select(".left-half")
              .attr("x", x(d.edition))
              .attr("width", cellWidth)
              .attr("fill", statusColors[d.pos_status])
              .attr("visibility", "visible")

            cellGroup.select(".right-half")
              .attr("visibility", "hidden")
          else
            # Ни один статус не активен: скрыть клетку
            cellGroup.selectAll("rect")
              .attr("visibility", "hidden")

          # Подсветка должна оставаться доступной для видимых клеток
          if (leftActive) or (rightActive)
            cellGroup.selectAll(".cell-hl-outer, .cell-hl-inner").attr("visibility", "visible")
          else
            cellGroup.selectAll(".cell-hl-outer, .cell-hl-inner").attr("visibility", "hidden")
        )
      )
  )

  # Контейнер SVG
  svg = container.append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", "translate(#{margin.left}, #{margin.top})")

  # Добавляем оси
  svg.append("g")
    .attr("transform", "translate(0, #{height})")
    .call(d3.axisBottom(x).tickFormat(formatEditionDate))
    .selectAll("text")
    .attr("transform", "rotate(-45)")
    .style("text-anchor", "end")
  svg.append("text")
    .attr("x", width / 2)
    .attr("y", height + 55)
    .attr("text-anchor", "middle")
    .style("font-size", "16px")
    .text("Редакция")
  svg.append("g")
    .call(d3.axisLeft(y))
  svg.append("text")
    .attr("transform", "rotate(-90)")
    .attr("y", -margin.left + 20)
    .attr("x", -height / 2)
    .attr("text-anchor", "middle")
    .style("font-size", "16px")
    .text("Ранг")

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

      # Подсветка одной системы по всем редакциям при наведении
      cellGroup.append("rect")
        .attr("class", "cell-hl-outer")
        .attr("x", x(d.edition))
        .attr("y", y(d.rank))
        .attr("width", cellWidth)
        .attr("height", cellHeight)
        .attr("fill", "none")
        .attr("stroke", "none")
        .attr("stroke-width", 3)
      cellGroup.append("rect")
        .attr("class", "cell-hl-inner")
        .attr("x", x(d.edition) + 2)
        .attr("y", y(d.rank) + 2)
        .attr("width", cellWidth - 4)
        .attr("height", cellHeight - 4)
        .attr("fill", "none")
        .attr("stroke", "none")
        .attr("stroke-width", 2)

      # Устанавливаем цвета и видимость
      leftActive = d.new_upd_status and activeFilters[d.new_upd_status]
      rightActive = d.pos_status and activeFilters[d.pos_status]

      if (leftActive) and (rightActive)
        # Оба статуса активны: клетка разделена
        cellGroup.select(".left-half")
          .attr("width", cellWidth / 2)
          .attr("fill", statusColors[d.new_upd_status])
          .attr("visibility", "visible")

        cellGroup.select(".right-half")
          .attr("width", cellWidth / 2)
          .attr("fill", statusColors[d.pos_status])
          .attr("visibility", "visible")
      else if leftActive
        # Только левый статус активен: закрасить всю клетку в левый цвет
        cellGroup.select(".left-half")
          .attr("x", x(d.edition))
          .attr("width", cellWidth)
          .attr("fill", statusColors[d.new_upd_status])
          .attr("visibility", "visible")

        cellGroup.select(".right-half")
          .attr("visibility", "hidden")
      else if rightActive
        # Только правый статус активен: закрасить всю клетку в правый цвет
        cellGroup.select(".left-half")
          .attr("x", x(d.edition))
          .attr("width", cellWidth)
          .attr("fill", statusColors[d.pos_status])
          .attr("visibility", "visible")

        cellGroup.select(".right-half")
          .attr("visibility", "hidden")
      else
        # Ни один статус не активен: скрыть клетку
        cellGroup.selectAll("rect")
          .attr("visibility", "hidden")

      # Подсветка одной системы по всем редакциям при наведении
      if d.machine_id != null and d.machine_id != undefined
        keyMid = (row) -> row.machine_id
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

          sysLine = heatmapTooltipSystemLineWithId(d)
          "Редакция: #{d.edition}\nМесто: #{d.rank}\n" +
          "Теги: #{tagsText}#{sysLine}"
        )
    )
