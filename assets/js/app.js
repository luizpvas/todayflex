// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.css"

import Alpine from 'alpinejs'
Alpine.start()

import { Elm } from '../elm/Main.elm'

window.addEventListener('load', () => {
  let editor = document.querySelector('#editor')
  if (editor) {
    let app = Elm.Main.init({
      node: editor,
      flags: {
        projectId: parseInt(editor.getAttribute('data-project-id')),
        latestId: new Date().getTime()
      }
    })

    document.addEventListener('keydown', ev => {
      app.ports.shortcutPressed.send(ev.key)
    });
  }
})

document.addEventListener('contextmenu', ev => {
  ev.preventDefault();
  return false;
});

