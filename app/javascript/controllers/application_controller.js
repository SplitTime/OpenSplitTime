import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  reloadWithTurbo() {
    Turbo.visit(window.location.toString(), {action: 'replace'})
  }
}
