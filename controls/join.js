const fs = require( "fs" )
const path = require( "path" )
const { execSync } = require( "child_process" )

const dir_entries = fs.readdirSync( "./" )
const root = ( execSync( "git rev-parse --show-toplevel" ) + "" ).replace( /\//g, "\\").replace( "\n", "" )
const current_dirname = ( __dirname + "" ).replace( root, "." )

//when you run join.js from node, this will be logged to console:
const command_info = [
  "Description:",
  "",
  "  Concatenates all files in directory with the following file structure into 'output.lua'.",
  "  Like so:",
  "",
  "    (# - )+ filename.lua",
  "",
  "  where (# (comment) - )+ evaluates to the following build order:",
  "",
  "    # = relative order",
  "    (comment) = comment - join.js just ignores this, so 'comment' functionally does nothing",
  "    if there is more than 1 instance of (# - ), the following # is relative to the previous #",
  "",
  "      such that",
  "        1 - 3 - 2 - 4 - filename.lua",
  "      means",
  "        4th file after the 2nd subgroup of 3rd subgroup of the 1st main group",
  "      where",
  "        2 - ...",
  "      comes after the 1st main group",
  "",
  "",
]
console.log( "\n------------------------[MANUAL]-----------------------\n\n" + command_info.join( "\n" ) )
console.log( "--------------------[BUILDING FILE]--------------------")
console.log( "\n# BUILDING " + current_dirname + " ...\n")



let to_join = []
let todos = []

dir_entries.forEach( entry => {
  let match = entry.match( /^(?<part>(?:\d *(?:\(.+\))? *- *)+)(?<name>.*(?:\.lua$))/ )
  if( match !== null ){
    let contents = fs.readFileSync( "./" + entry ) + ""

    let ids = match.groups.part.replace(/\([^\)]+\)/g,"").replace(/\s+/g, '').split("-"); ids.pop()
    let name = match.groups.name

    let todo_matches = contents.matchAll(/^\s*--todo:(.*)$/gmi);
    for( const todo_match of todo_matches ){
      let todo_chunk = [
        "-------------------------------------------------------",
        "--[" + name.toUpperCase() + "] (from part " + ids.join("-") + "):",
        "--##" + todo_match[ 1 ],
        ""
      ]
      todos.push( todo_chunk.join("\n") )

    }
    let spot = to_join
    for( i = 0; i < ids.length; i++ ){

      if( i === ids.length - 1 ){

        let log = [
          "[" + ids.join("-") + "]",
          "        " + name.toUpperCase()
        ].join("\n")

        console.log( log )
        spot[ ids[ i ] ] = "--------------------[JOIN.JS PART]---------------------\n--PARTNAME:\n--" + name + "\n--FILEPATH:\n--" + current_dirname + "\\" + entry + "\n\n" + contents

      }else{

        if( typeof spot[ ids[ i ] ] == "undefined" ) spot[ ids[ i ] ] = []
        spot = spot[ ids[ i ] ]

      }

    }

  }

})

output = [
  "",
  "--### JOIN.JS BUILT THIS LUA FILE ###",
  "--This script was created from lua files in " + current_dirname + " using the 'join.js' in nodejs (in POWERSHELL, run: node join.js)\n",
  to_join.flat( Infinity ).join( "\n" ),
  "",
  "-----------------------[TODOS:]------------------------",
  todos.join("\n")
].join("\n")

fs.writeFileSync("./output.lua", output);
console.log( "# FILE BUILT! => \n\n  " + current_dirname + "\\output.lua\n\n")
