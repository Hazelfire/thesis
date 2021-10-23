import * as d3 from 'd3'
import itpFile from './itps.csv'
import itpGithubFile from './itp_github_stats.csv'
import libraryIndexFile from './libraries.csv'
import type {Package} from './mathcard'
import {addLibraryWidget} from './mathcard'
import './style.css'
import features from './features.json'
import itpProjects from './itpprojects.csv'

type TPCategory = "ITP" | "ATP" | "ATP+ITP";
type BasedOn = "Syllogism" | "FP" | "LF" | "DP";
type Logic = "TT" | "HOL" | "FOL" | "FOL+HOL" | "HOTT";
type TruthValue = "Binary" | "Intuition";
type Calculus = "Inductive" | "Deductive" | "Ded+Indu";
type Paradigm = "Func" | "Impe" | "LP" | "Decl" | "Func+OO";

function requireAll(ctx: __WebpackModuleApi.RequireContext) : {[key: string]: string}  { 
  let keys = ctx.keys();
  let values = keys.map(ctx);
  return keys.reduce((o: any, k: string, i) => { o[k.slice(2)] = values[i]; return o; }, {});
}

const logos = requireAll(require.context('./logos/', true, /\.*$/));
const libraryFiles = requireAll(require.context('./library_data/', true, /\.csv$/));

type ITP = {
  name: string,
  systemType: "TP",
  tpCategory: TPCategory,
  basedOn: BasedOn,
  logic: Logic,
  truthValue: TruthValue,
  calculus: Calculus,
  setTheory: boolean,
  paradigm: Paradigm,
  architecture: string,
  programmingLanguage: string,
  userInterface: string,
  platforms: string,
  scalability: boolean,
  multiThreaded: boolean,
  ide: boolean,
  library: boolean,
  programmability: boolean,
  tactic: boolean,
  logo: string,
  homepage: string,
  contributors: string,
  firstRelease: string,
  lastReleaseDate?: Date,
  lastReleaseName?: string,
  githubUrl?: string,
  libraries: Library[]
  projects: Project[]
}

type Project = {
  name: string,
  prover: string,
  description: string,
  citation: string
}

type Library = {
  itp: string,
  section: string,
  file: string,
  url: string,
  entries: Package[]
}

type ITPGithubStats = {
  name: string,
  lastReleaseDate: Date,
  lastReleaseName: string,
  url: string
}

function parsePackage(v : d3.DSVRowString<string>){
  return {
    msc: v.msc, 
    name: v.package, 
    authors: v.authors, 
    description: v.description, 
    category: v.category, 
    url: v.url, 
    verified: v.verified === 'True',
  }
}

function createItpSection(parent: d3.Selection<HTMLElement, ITP, d3.BaseType,unknown>, key: keyof ITP){
  function expandDetail(this: Element){
    d3.select(this)
      .on('click', collapseDetail)
    let libraryInfoNode : d3.Selection<HTMLElement, ITP, null, undefined> = d3.select(this.parentElement)
      .append("div")
      .attr("class", "detail-information") as d3.Selection<HTMLElement, ITP, null, undefined>

    libraryInfoNode.append("div")
      .text((i : ITP) => {
        let foundFeature = features.find(f => f.key === key)
        if(foundFeature){
          return foundFeature.values.find(f => f.value === i[key]).description
        }
        else {
          return ""
        }
      })

  }

  function collapseDetail(){
    d3.select(this)
      .on('click', expandDetail)
    d3.select(this.parentElement)
      .select(".detail-information")
      .remove()
  }

  let libraryDetail = parent.append("div")
    .attr("class", "itp-detail")

  libraryDetail.append("div")
    .attr("class", "itp-detail-header clickable")
    .on('click', expandDetail)
    .text(i => {
      let foundFeature = features.find(f => f.key === key)
      if(foundFeature){
        return key + ": " + foundFeature.values.find(f => f.value === i[key]).name
      }
      else {
        return key + ": " + i[key]
      }
    })
}

function readITPGithubStats (v : d3.DSVRowString<string>) : ITPGithubStats {
  return {
    name: v.name,
    lastReleaseDate: new Date(v["latest_release_date"]),
    lastReleaseName: v["latest_release_name"],
    url: v["url"]
  };
}

function readITP(v : d3.DSVRowString<string>, stats: ITPGithubStats[], libraries: Library[], projects: Project[]) : ITP {
  let itp : ITP = {
    name: v.Name,
    systemType: v["System Type"] as "TP",
    tpCategory: v["Theorem Prover Category"] as TPCategory,
    basedOn: v["System Based on"] as BasedOn,
    logic: v["Logic Used"] as Logic,
    truthValue: v["System's Truth Value"] as TruthValue,
    calculus: v["Calculus"] as Calculus,
    setTheory: v["Set Theoretic Support"] === "Yes",
    paradigm: v["Programming Paradigm"] as Paradigm,
    architecture: v["System Architecture"],
    programmingLanguage: v["Programming Language"],
    userInterface: v["User Interface"],
    platforms: v["Platform Support"],
    scalability: v["Scalability"] === "Yes",
    multiThreaded: v["Multi-threaded"] === "Yes",
    ide: v["IDE"] == "Yes",
    library: v["Library Support"] == "Yes",
    programmability: v["Programmability"] == "Yes",
    tactic: v["Tactic Language Support"] == "Yes",
    logo: v["Logo"],
    homepage: v["Homepage"],
    contributors: v["Contributors"],
    firstRelease: v["1stRelease"],
    libraries: libraries.filter(l => l.itp === v.Name),
    projects: projects.filter(l => l.prover === v.Name)
  };

  let foundStats = stats.find(s => s.name === itp.name);
  if(foundStats){
    itp.githubUrl = foundStats.url;
    itp.lastReleaseName = foundStats.lastReleaseName;
    itp.lastReleaseDate = foundStats.lastReleaseDate;
  }
  return itp;
}

function createProverItem(element : d3.Selection<HTMLElement, ITP, d3.BaseType, unknown>){
  element.append("td").append("img")
    .attr("src", (i: ITP) => logos[i.logo])
    .attr("class", "itp-prover-logo")
    .attr("width", "50")
  
  element.append("td").append("b")
    .attr("class", "itp-title")
    .text(i => i.name)

  let detailsElement = element.append("div")
    .attr("class", "itp-details")
  
  detailsElement.append("div")
    .attr("class", "itp-author")
    .text(i => i.contributors)

  element.append("td").append("div")
    .attr("class", "itp-homepage")
    .append("a")
      .attr("href", i => i.homepage)
      .text("Homepage")

  detailsElement.append("div")
    .attr("class", "itp-latest-release")
    .text(i => {
      if(i.lastReleaseDate){
        return "Latest release: " + i.lastReleaseDate.toDateString() + " - " + i.lastReleaseName
      } else {
        return "Unknown latest release"
      }})

  createItpSection(detailsElement, "basedOn")
  createItpSection(detailsElement, "logic")
  createItpSection(detailsElement, "truthValue")
  createItpSection(detailsElement, "calculus")
  createItpSection(detailsElement, "setTheory")
  createItpSection(detailsElement, "architecture")
  createItpSection(detailsElement, "tactic")
  createItpSection(detailsElement, "programmability")
  createItpSection(detailsElement, "programmingLanguage")
  createItpSection(detailsElement, "ide")
  createItpSection(detailsElement, "userInterface")
  createItpSection(detailsElement, "paradigm")

  function expandLibrary(this: Element){
    d3.select(this)
      .on('click', collapseLibrary)
    let libraryInfoNode : d3.Selection<HTMLElement, ITP, null, undefined> = d3.select(this.parentElement)
      .append("div")
      .attr("class", "library-information") as d3.Selection<HTMLElement, ITP, null, undefined>

    libraryInfoNode.append("div")
      .text((i : ITP) => {
        if(i.library){
          return i.name + " has a library. "
        }
        else {
          return i.name + " does not have a library."
        }
      })

    let hasLibrary = libraryInfoNode.selectAll(".library")
      .data((i: ITP) => {
        return i.libraries
      })
      .enter().append("div")

    addLibraryWidget(hasLibrary)
      
  }

  function collapseLibrary(){
    d3.select(this)
      .on('click', expandLibrary)
    d3.select(this.parentElement)
      .select(".library-information")
      .remove()
    
  }

  let libraryDetail = detailsElement.append("div")
    .attr("class", "itp-detail")

  libraryDetail.append("div")
    .attr("class", "itp-detail-header clickable")
    .on('click', expandLibrary)
    .text(i => i.library ? "Has library support" : "Has no library support")

  createItpSection(detailsElement, "library")
  createItpSection(detailsElement, "multiThreaded")
  createItpSection(detailsElement, "scalability")
  createItpSection(detailsElement, "platforms")
  createItpSection(detailsElement, "firstRelease")

  detailsElement.append("div")
    .selectAll(".project")
    .data(i => i.projects)
    .enter()
    .append("div")
      .text(p => p.name)

}

function parseLibrary(v : d3.DSVRowString<string>): Library {
  return {
    itp: v.name,
    section: v.section,
    file: v.file,
    url: v.url,
    entries: []
  }
}

async function readLibraryFiles(l : Library): Promise<Library> {
  let entries = (await d3.csv(libraryFiles[l.file])).map(parsePackage)
  return {
    ...l,
    entries
  }
}

function parseProject(v : d3.DSVRowString<string>): Project {
  return {
   name: v.Name,
   prover: v.Prover,
   description: v.Description,
   citation: v.Citation
  }
}

async function main(){
  let libraries = (await d3.csv(libraryIndexFile)).map(parseLibrary)
  let projects = (await d3.csv(itpProjects)).map(parseProject)
  let filledLibraries = await Promise.all(libraries.map(readLibraryFiles))
  let itpGithubStats = (await d3.csv(itpGithubFile)).map(readITPGithubStats)
  let itps = (await d3.csv(itpFile)).map(i => readITP(i, itpGithubStats, filledLibraries, projects)).filter(i => i.tpCategory !== "ATP")
  let itpElement = d3.select("#itps")
    .append("table")
    .selectAll(".itp")
    .data(itps)
    .enter()
    .append("tr")
      .attr("class", "itp")

  createProverItem(itpElement);
}

main()
