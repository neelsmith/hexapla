# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "dashboard"))
Pkg.instantiate()

DASHBOARD_VERSION = "0.1.0"
# Variables configuring the app:  
#
#  1. location  of the assets folder (CSS, etc.)
#  2. port to run on
# 
# Set an explicit path to the `assets` folder
# on the assumption that the dashboard will be started
# from the root of the gh repository!
assets = joinpath(pwd(), "dashboard", "assets")
DEFAULT_PORT = 8050

using Dash


app = if haskey(ENV, "URLBASE")
    dash(assets_folder = assets, url_base_pathname = ENV["URLBASE"])
else 
    dash(assets_folder = assets)    
end

app.layout = html_div(className = "w3-container") do
    html_div(className = "w3-container w3-light-gray w3-cell w3-mobile w3-border-left w3-border-right w3-border-gray",
        children = [dcc_markdown("*Dashboard version*: **$(DASHBOARD_VERSION)** ([version notes](https://homermultitext.github.io/dashboards/lightbox/))")]),


    html_h1() do 
        dcc_markdown("Hexapla text reader")
    end,

    html_div(className="w3-container",
        html_div(className="w3-col l6 m6",
        children = [
            dcc_markdown("Set the slider to use 1-6 columns"),
            dcc_slider(
                id="numcolumns",
                min=1,
                max=6,
                step=1,
                value=2
            )
        ])
    ),

    
    html_div(className="w3-container", id="columns")

    
        
end



function gencols(n)
    twelfths = floor(12 / n) |> Int

    results = Component[]
    for i in 1:n
        # generate column
        push!(results, html_div(className="w3-col l$(twelfths) m$(twelfths)", 
        dcc_markdown("Hi")))
    end
    results
end

callback!(app,
    Output("columns", "children"),
    Input("numcolumns", "value")
) do colnum 
    twelfths = floor(12 / colnum)
    #dcc_markdown("Make $(colnum) columns with 12ths grouped in divisions of $(twelfths) ")
    gencols(colnum)
end


run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)
