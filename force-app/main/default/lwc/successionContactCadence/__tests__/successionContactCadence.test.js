import { createElement } from "lwc";
import SuccessionContactCadence from "c/successionContactCadence";

describe("c-succession-contact-cadence", () => {
  afterEach(() => {
    // Reset DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders without errors", () => {
    const element = createElement("c-succession-contact-cadence", {
      is: SuccessionContactCadence
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Verify component renders
    const card = element.shadowRoot.querySelector("lightning-card");
    expect(card).not.toBeNull();
    expect(card.title).toBe("Contact Cadence Progress");
  });

  it("shows loading spinner initially", () => {
    const element = createElement("c-succession-contact-cadence", {
      is: SuccessionContactCadence
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Verify loading state
    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).not.toBeNull();
  });

  it("has recordId property set", () => {
    const element = createElement("c-succession-contact-cadence", {
      is: SuccessionContactCadence
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Verify recordId is set (public @api property)
    expect(element.recordId).toBe("500xx000000000AAAA");
  });
});
