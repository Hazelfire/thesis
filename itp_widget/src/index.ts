import {Elm} from './Main';
import msc from './msc.json';
import itpFile from './itps.csv'
import itpGithubFile from './itp_github_stats.csv'
import libraryIndexFile from './libraries.csv'
import counterExampleFile from './counterExampleIntegrations.csv'
import counterExampleGeneratorFile from './counterExampleGenerators.csv'
import itpProjects from './projects.csv'
import * as d3 from 'd3'
import './style.css';
import embed from 'vega-embed';
import { saveAs } from 'file-saver';


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

export type Package = {
  name: string,
  url: string,
  description: string,
  authors: string,
  verified: boolean,
  msc: string
}


type Library = {
  itp: string,
  section: string,
  file: string,
  url: string,
  entries: Package[]
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

type Project = {
  name: string,
  prover: string,
  author: string,
  description: string,
  website: string,
  category: string,
  startDate: number,
  endDate: number
}

type ProjectIndex = {
  name: string,
  file: string
}

function parseProjectIndex(v : d3.DSVRowString<string>): ProjectIndex {
  return {
    name: v['name'],
    file: v['file']
  }
}

function parseProject(v : d3.DSVRowString<string>): Project {
  return {
   name: v.name,
   prover: '',
   author: v.author,
   startDate: v.start_date == "" ? null : parseInt(v.start_date),
   endDate: v.end_date == "" ? null : parseInt(v.end_date),
   description: v.description,
   website: v.website,
   category: v.category
  }
}

async function readProjectFiles(i: ProjectIndex): Promise<Project[]> {
  let projects = (await d3.csv(projectFiles[i.file])).map(parseProject)
  return projects.map((p) => ({...p, prover: i.name}))
}

async function readLibraryFiles(l : Library): Promise<Library> {
  let entries = (await d3.csv(libraryFiles[l.file])).map(parsePackage)
  return {
    ...l,
    entries
  }
}

function requireAll(ctx: __WebpackModuleApi.RequireContext) : {[key: string]: string}  { 
  let keys = ctx.keys();
  let values = keys.map(ctx);
  return keys.reduce((o: any, k: string, i) => { o[k.slice(2)] = values[i]; return o; }, {});
}

type ITPGithubStats = {
  name: string,
  lastReleaseDate: Date,
  lastReleaseName: string,
  url: string,
  releaseUrl: string
}
function readITPGithubStats (v : d3.DSVRowString<string>) : ITPGithubStats {
  return {
    name: v.name,
    lastReleaseDate: new Date(v["latest_release_date"]),
    lastReleaseName: v["latest_release_name"],
    url: v["url"],
    releaseUrl: v["release_url"]
  };
}

type ITP = {
  name: string,
  systemType: string,
  tpCategory: string,
  basedOn: string,
  logic: string,
  truthValue: string,
  calculus: string,
  setTheory: boolean,
  paradigm: string,
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
  utf8Library: string,
  counterexample: string,
  homepage: string,
  contributors: string,
  firstRelease: string,
  lastReleaseDate: number,
  lastReleaseName: string,
  lastReleaseUrl: string,
  releasesUrl: string,
  libraries: Library[]
  projects: Project[],
  counterExampleIntegrations: CounterExampleIntegration[]
}

type CounterExampleIntegration = {
  prover: string,
  name : string,
  citation: string
}

type CounterExampleGenerator = {
  name: string,
  description: string
}

function readCounterExampleGenerator(v : d3.DSVRowString<string>) : CounterExampleGenerator{
  return {
    name: v.name,
    description: v.description
  }
}

function readITP(v : d3.DSVRowString<string>, stats: ITPGithubStats[], libraries: Library[], projects: Project[], counterExampleIntegrations : CounterExampleIntegration[]) : ITP {
  let itp : ITP = {
    name: v.Name,
    systemType: v["System Type"] as "TP",
    tpCategory: v["Theorem Prover Category"],
    basedOn: v["System Based on"],
    logic: v["Logic Used"],
    truthValue: v["System's Truth Value"],
    calculus: v["Calculus"],
    setTheory: v["Set Theoretic Support"] === "Yes",
    paradigm: v["Programming Paradigm"],
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
    utf8Library: v["UTF8 Library"],
    counterexample: v["Counterexamples"],
    logo: v["Logo"] == "" ? "" : logos[v["Logo"]],
    homepage: v["Homepage"],
    contributors: v["Contributors"],
    firstRelease: v["1stRelease"],
    libraries: libraries.filter(l => l.itp === v.Name),
    projects: projects.filter(l => l.prover === v.Name),
    lastReleaseName: '',
    lastReleaseDate: 0,
    lastReleaseUrl: '',
    releasesUrl: '',
    counterExampleIntegrations: counterExampleIntegrations.filter(ceg => ceg.prover == v.Name)
  };

  let foundStats = stats.find(s => s.name === itp.name);
  if(foundStats){
    itp.lastReleaseUrl = foundStats.releaseUrl;
    itp.lastReleaseName = foundStats.lastReleaseName;
    itp.lastReleaseDate = foundStats.lastReleaseDate.getTime();
    itp.releasesUrl = foundStats.url;
  }
  return itp;
}

const logos = requireAll(require.context('./logos/', true, /\.*$/));
const libraryFiles = requireAll(require.context('./library_data/', true, /\.csv$/));
const projectFiles = requireAll(require.context('./project_data/', true, /\.csv$/));

function readCounterExampleIntegrations(v : d3.DSVRowString<string>) : CounterExampleIntegration {
  return {
    name: v.name,
    prover: v.prover,
    citation: ''
  };

}

async function main(){
  let libraries = (await d3.csv(libraryIndexFile)).map(parseLibrary)
  let projects = (await d3.csv(itpProjects)).map(parseProjectIndex)
  let filledProjects = [].concat.apply([], await Promise.all(projects.map(readProjectFiles)))
  let filledLibraries = await Promise.all(libraries.map(readLibraryFiles))
  let itpGithubStats = (await d3.csv(itpGithubFile)).map(readITPGithubStats)
  let counterExampleIntegrations = (await d3.csv(counterExampleFile)).map(readCounterExampleIntegrations);
  let counterExampleGenerators = (await d3.csv(counterExampleGeneratorFile)).map(readCounterExampleGenerator);
  let itps = (await d3.csv(itpFile)).map(i => readITP(i, itpGithubStats, filledLibraries, filledProjects, counterExampleIntegrations)).filter(i => i.tpCategory !== "ATP")
  let elm = Elm.Main.init({
    node: document.getElementById('itps'),
    flags: {
      msc: msc,
      provers: itps,
      counterExampleGenerators: counterExampleGenerators
    }
  })

  elm.ports.renderVegaSpec.subscribe((spec) => {
    requestAnimationFrame(() => {
      // Change actions to true to display links to source, editor and image.
      embed("#" + spec.id, spec.spec, { actions: false }).catch(console.warn);
    });
  });
  
  elm.ports.saveFile.subscribe((file) => {
    let blob = new Blob([file.contents], {type: "text/plain;charset=utf-8"});
    saveAs(blob, file.name);

  })
}

main()
