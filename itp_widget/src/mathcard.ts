import * as d3 from 'd3'
import msc from './msc.json'

type BotClassification = {
  name: string,
  code: string,
  packages?: Package[],
  packageCount?: number
}

type MidClassification = {
  name: string,
  code: string,
  classifications: BotClassification[]
  packages?: Package[],
  packageCount?: number
}

type TopClassification = {
  short_name: string,
  code: string,
  subclassifications: MidClassification[],
  classifications: BotClassification[],
  packages?: Package[],
  packageCount?: number
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

function createBotClassification(packages: Package[], botClass : BotClassification): BotClassification{
  let my_packages = packages.filter(p => p.msc.toLowerCase() === botClass.code.toLowerCase());
  return {
    'name': botClass.name,
    'code': botClass.code,
    'packages': my_packages,
    'packageCount': my_packages.length
  };
}

function addPackagesToClassifications(packages: Package[], mscClass : TopClassification[]) : TopClassification[]{
  return mscClass.map(topClass => {
    let my_packages =  packages.filter(p => p.msc.toLowerCase() === topClass.code.toLowerCase());
    let classifications = topClass.classifications.map(botClass => createBotClassification(packages, botClass));
    let classPackageCount = classifications.map(c => c.packageCount).reduce((a, b) => a + b);
    let subclassifications = topClass.subclassifications.map(midClass => {
        let my_packages = packages.filter(p => p.msc.toLowerCase() === midClass.code.toLowerCase());
        let classifications = midClass.classifications.map(botClass => createBotClassification(packages, botClass ));
        let packageCountClassifications = classifications.map(c => c.packageCount).reduce((a, b) => a + b);
        return {
          'name': midClass.name,
          'code': midClass.code,
          'packages': my_packages,
          'classifications': classifications,
          'packageCount': packageCountClassifications + my_packages.length
        }
    });
    let subClassPackageCount = subclassifications.map(c => c.packageCount).reduce((a, b) => a + b);

    return {
      'short_name': topClass.short_name,
      'code': topClass.code,
      'packages': my_packages,
      'classifications': classifications,
      'subclassifications': subclassifications,
      'packageCount': my_packages.length + subClassPackageCount + classPackageCount
    }
  });
}

function categoryClass(catClass : string){
  return ((d : BotClassification | MidClassification | TopClassification) =>
   {
      if(d.packageCount == 0){
        return catClass + " emptycategory"
      }
      else{
        return catClass
      }
     
   })
}
function isTop(data: MidClassification | TopClassification): data is TopClassification {
  return (data as TopClassification).subclassifications !== undefined;
}

function appendPackage(selection : d3.Selection<HTMLElement, Package, HTMLElement, unknown>){
  let packageNode = selection.append("span")
    .attr('class', 'package')

  packageNode.append("span")
    .text(t => t.name)
    .attr('class', t => t.verified ? "clickable verified" : "unverified")
    .on('click', expandPackage)

}

function expandPackage(_ : MouseEvent, __: Package){
  d3.select(this)
    .on('click', collapsePackage)
  let packageNode = d3.select(this.parentNode)
    .append("div")
    .attr("class", "package-details")

  packageNode.append("a")
    .attr("href", (p:Package) => p.url)
    .attr("target", "_blank")
    .text("Homepage")

  packageNode.append("div")
    .text((p: Package) => "Authors: " +p.authors)

  packageNode.append("div")
    .text((p: Package) => p.description)

}

function collapsePackage(_ : MouseEvent, __ : Package){
  d3.select(this)
    .on('click', expandPackage)

  d3.select(this.parentNode)
    .select(".package-details").remove()
}

function expandBot(_ : MouseEvent, __ : BotClassification) {
  d3.select(this)
    .on('click', collapseBot);

  const packageNode = d3.select(this.parentNode)
    .append("ul")
    .selectAll('.packages')
    .data((d : BotClassification) => d.packages)
    .enter()
      .append('li')

  appendPackage(packageNode)
}

function collapseBot(_ : MouseEvent, __: BotClassification){
  d3.select(this)
    .on('click', expandBot)
  d3.select(this.parentNode)
    .selectAll("ul")
    .remove()
}

function expand(_ : MouseEvent, d : MidClassification | TopClassification){
  if(isTop(d)){
    d3.select(this)
      .on('click', collapse)

    let botElements = d3.select(this.parentNode)
      .append("ul")
      .selectAll('.midclass')
      .data((d : TopClassification) => d.classifications)
      .enter()
        .append('li')
        .attr("class", categoryClass("botclass"))

    botElements.append("span")
      .attr("class", "clickable")
      .on('click', expandBot)
      .text(t => t.code + ": " + t.name + " (" +t.packageCount + " packages)")

    let children = d3.select(this.parentNode)
      .append("ul")
      .selectAll('.midclass')
      .data((d : TopClassification) => d.subclassifications)
      .enter()
        .append('li')
        .attr("class", categoryClass("midclass"))

    children.append("span")
        .attr("class", "clickable")
        .on('click', expand)
        .text(t => t.code + ": " + t.name + " (" +t.packageCount + " packages)")

    /* packages */
    let packageNode = d3.select(this.parentNode)
      .append("ul")
      .selectAll('.packages')
      .data((d : TopClassification) => d.packages)
      .enter()
        .append('li')

    appendPackage(packageNode)
  }
  else {
    d3.select(this)
     .on('click', collapse)

    /* Bottom Classifications from Mid */
    let bottomNode = d3.select(this.parentNode)
     .append("ul")
      .attr("class", ".botclass-list")
      .selectAll(".botclass")
        .data((d: MidClassification) => d.classifications)
        .enter()
        .append("li")
          .attr("class", categoryClass("botclass"))

    bottomNode.append("span")
      .on('click', expandBot)
      .attr("class", "clickable")
      .text(t => t.code + ": " + t.name + " (" +t.packageCount + " packages)")

    /* Packages on mid classification */
    let packageNode = d3.select(this.parentNode)
      .append("ul")
      .selectAll('.packages')
      .data((d : MidClassification) => d.packages)
      .enter()
        .append('li')
    appendPackage(packageNode)
    }
}

function collapse(e : MouseEvent, _:  MidClassification){
  d3.select(this)
    .on('click', expand)
  d3.select(this.parentNode)
    .selectAll("ul")
    .remove()
  e.stopPropagation()
}

export function addLibraryWidget(libraryWidget: d3.Selection<HTMLElement,Library,HTMLElement, unknown>){
  console.log(msc)
  let top_classification = libraryWidget.selectAll(".topclass")
    .data(i => addPackagesToClassifications(i.entries, msc))
    .enter()
    .append("div")
      .attr("class", categoryClass("topclass"))

  top_classification.append("span")
    .attr("class", "clickable")
    .text(t => t.code + ": " + t.short_name + "(" + t.packageCount + " packages)")
    .on('click', expand)
}
