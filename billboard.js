// https://www.billboard.com/artist/taylor-swift/chart-history/hsi/
// JSON.stringify([...document.querySelectorAll(".o-chart-results-list-row")].reduce((a,e) => Object.assign(a,{ [e.querySelector("h3").innerText.toLowerCase]: parseInt(e.querySelector(".artist-chart-row-peak-pos").innerText)}), {}))

const { readdirSync, writeFileSync } = require("fs")
const billboard = require("./billboard.json")

readdirSync("./albums").forEach(dir => {
  let album = require(`./albums/${dir}`)
  album = album.map(track => {
    const name = track.name.split(/ - .*$/)[0].split(/ \(feat. [^)]*\)/).join("").replace(/‘|’/g,"'")
    return { ...track, name, position: billboard[name.toLowerCase()] | 0 }
  })
  writeFileSync(`./albums/${dir}`, JSON.stringify(album, null, 2))
})
