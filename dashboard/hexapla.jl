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
datadir = joinpath(pwd(),"data")
DEFAULT_PORT = 8050

using Dash

function loadtexts(dir)
    txts = filter(f -> endswith(f, ".txt"), readdir(dir))
    langcodes = map(t -> t[1:3], txts)
    metadatalines = readlines(joinpath(dir, "sources.cex"))
    metadata = map(ln -> split(ln, "|"), metadatalines[2:end])
    mddict = Dict()
    for cols in metadata
        mddict[cols[4]] = cols[1]
    end
    (mddict, txts, langcodes)
end
(titlesdict, filenames, langs)  = loadtexts(datadir)

function msoptions(files, titles)
    opts = []
    for f in files
        push!(opts, (label = titles[f], value = f))
    end
    opts
end

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
    children = [
        html_div(className="w3-col l6 m6",
            dcc_dropdown(
                id="translations",
                options = msoptions(filenames, titlesdict),
                value = "MTL",
            )
        ),
        
        

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
    ]
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
