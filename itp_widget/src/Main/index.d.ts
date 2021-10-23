// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/dillonkearns/elm-typescript-interop
// Type definitions for Elm ports

export namespace Elm {
  namespace Main {
    export interface App {
      ports: {
        renderVegaSpec: {
          subscribe(callback: (data: any) => void): void
        }
        saveFile: {
          subscribe(callback: (data: { contents: string; name: string }) => void): void
        }
      };
    }
    export function init(options: {
      node?: HTMLElement | null;
      flags: { provers: { name: string; systemType: string; tpCategory: string; basedOn: string; logic: string; truthValue: string; calculus: string; setTheory: boolean; paradigm: string; architecture: string; programmingLanguage: string; userInterface: string; platforms: string; scalability: boolean; counterexample: string; utf8Library: string; multiThreaded: boolean; ide: boolean; library: boolean; programmability: boolean; tactic: boolean; logo: string; homepage: string; contributors: string; firstRelease: string; lastReleaseDate: number; lastReleaseName: string; lastReleaseUrl: string; releasesUrl: string; libraries: { itp: string; section: string; file: string; url: string; entries: { name: string; url: string; description: string; authors: string; verified: boolean; msc: string }[] }[]; projects: { name: string; author: string; prover: string; description: string; website: string; startDate: number | null; endDate: number | null; category: string }[]; counterExampleIntegrations: { name: string; prover: string; citation: string }[] }[]; counterExampleGenerators: { name: string; description: string }[]; msc: { short_name: string; code: string; subclassifications: { name: string; code: string; classifications: { name: string; code: string }[] }[]; classifications: { name: string; code: string }[] }[] };
    }): Elm.Main.App;
  }
}