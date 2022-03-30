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

booksdict = Dict(
    "GEN" => "Genesis",
    "EXO" => "Exodus",
    "LEV" => "Leviticus",
    "LUK" => "Gospel according to Luke"
)

function booksmenu(dir)
    f = joinpath(dir, "latVUC_vpl.txt")
    books = map(cols -> cols[1], readlines(f) .|> split ) |> unique
    menu = []
    for b in books
        push!(menu, (label = b, value = b))
    end
    menu
end


app = if haskey(ENV, "URLBASE")
    dash(assets_folder = assets, url_base_pathname = ENV["URLBASE"])
else 
    dash(assets_folder = assets)    
end

app.layout = html_div(className = "w3-container") do
    html_div(className = "w3-container w3-light-gray w3-cell w3-mobile w3-border-left w3-border-right w3-border-gray",
        children = [dcc_markdown("*Dashboard version*: **$(DASHBOARD_VERSION)** ([version notes](https://homermultitext.github.io/dashboards/lightbox/))")]
    ),


    html_h1() do 
        dcc_markdown("Hexapla text reader")
    end,
    html_h3("Select texts and passage"),
    dcc_markdown("Optionally filter by language, then select one or more texts to view."),

    html_div(className="w3-container",
    children = [
        html_div(className="w3-col l3 m3",
        children = [
            dcc_markdown("*Filter texts by languages*:"),
            dcc_checklist(
                id="languages",
                options = [
                    Dict("label" => "Arabic", "value" => "arb"),
                    Dict("label" => "English", "value" => "eng"),
                    Dict("label" => "French", "value" => "fra"),
                    Dict("label" => "German", "value" => "deu"),
                    Dict("label" => "Greek", "value" => "grc"),
                    Dict("label" => "Hebrew", "value" => "hbo"),
                    Dict("label" => "Latin", "value" => "lat"),
                    Dict("label" => "Russian", "value" => "rus")
                ]
            )
        ]),
    
        html_div(className="w3-col l5 m5",
        children = [
            dcc_markdown("*Translations to include:*"),
            dcc_checklist(id="translations")
        ]),
 
        html_div(className="w3-col l1 m1",
        children = [
            dcc_markdown("*Book*:"),
            dcc_dropdown(
                id = "book",
                options = booksmenu(datadir)
            )
        ]),

        html_div(className="w3-col l3 m3",
        children = [
            dcc_markdown("*Chapter/verse* (e.g., `1:1`):")
            dcc_input(
                    id="verse",
                    placeholder="1:1",
                    debounce = true
            )
        ])
    ]),

    html_div(className="w3-container", id = "header"),
    html_div(className="w3-container", id="columns") 
end

# 
function xlationoptions(files, titles, langlist)
    opts = []
    for f in files
        push!(opts, (label = titles[f], value = f))
    end
    opts
end

function genheader(bk,ref,dict)
    if isnothing(bk) || isnothing(ref)
        ""  
    elseif haskey(dict, bk)
        dcc_markdown("## *$(dict[bk])*, $(ref)")
    else
        dcc_markdown("## `$(bk)`, $(ref)")
    end

end

function gencols(optlist, titles, files, bk, psg)
    
    if isempty(optlist)
        ""
    else
        n = length(optlist)
        twelfths = floor(12 / n) |> Int

        results = Component[]
        for i in 1:n
            # generate column
            push!(results, html_div(className="w3-col l$(twelfths) m$(twelfths)", 
            dcc_markdown("### " * titles[optlist[i]])))
        end
       results
    end
end

callback!(app,
    Output("translations", "options"),
    Input("languages", "value")
) do langg
    if isnothing(langg)
        xlationoptions(filenames, titlesdict, [])
    else
        xlationoptions(filenames, titlesdict, langg)
    end
end
callback!(app,
    Output("header", "children"),
    Output("columns", "children"),
    Input("translations", "value"),
    Input("book", "value"),
    Input("verse", "value")
) do xlations, bk, psg
    cols = isnothing(xlations) ? gencols([], titlesdict, filenames, bk, psg) : gencols(xlations, titlesdict, filenames, bk, psg)
    hdr = genheader(bk, psg, booksdict)
    (hdr, cols)
end

run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)
