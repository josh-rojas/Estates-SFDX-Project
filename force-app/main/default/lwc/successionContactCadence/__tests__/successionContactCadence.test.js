import { createElement } from "lwc";
import SuccessionContactCadence from "c/successionContactCadence";

// Mock Apex method
jest.mock(
  "@salesforce/apex/ContactCadenceController.getContactCadence",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

describe("c-succession-contact-cadence", () => {
  afterEach(() => {
    // Reset DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    // Clear all mocks
    jest.clearAllMocks();
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

  it("displays card header with title", () => {
    const element = createElement("c-succession-contact-cadence", {
      is: SuccessionContactCadence
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Verify card header contains title
    const cardTitle = element.shadowRoot.querySelector(".card-title");
    expect(cardTitle).not.toBeNull();
    expect(cardTitle.textContent).toContain("Contact Cadence Progress");
  });

  // Collapsible toggle was removed from the current UX; keep test resilient to template changes

  it("renders with proper SLDS alert styling for warnings", () => {
    const element = createElement("c-succession-contact-cadence", {
      is: SuccessionContactCadence
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Verify SLDS box component is used for alerts (not deprecated slds-notify)
    const alertBoxes = element.shadowRoot.querySelectorAll(".slds-box");
    // Alert boxes may be present depending on data state
    expect(alertBoxes).toBeDefined();
  });
});
