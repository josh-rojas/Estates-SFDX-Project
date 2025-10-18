import { createElement } from "lwc";
import RecordPathwaySelection from "c/recordPathwaySelection";
import { updateRecord } from "lightning/uiRecordApi";

// Mock lightning/uiRecordApi
jest.mock(
  "lightning/uiRecordApi",
  () => {
    return {
      updateRecord: jest.fn().mockResolvedValue({}),
      getRecord: jest.fn()
    };
  },
  { virtual: true }
);

// Mock lightning/actions
jest.mock(
  "lightning/actions",
  () => {
    return {
      CloseActionScreenEvent: class MockCloseActionScreenEvent extends CustomEvent {
        constructor() {
          super("close");
        }
      }
    };
  },
  { virtual: true }
);

describe("c-record-pathway-selection", () => {
  afterEach(() => {
    // Reset DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    // Reset mocks
    jest.clearAllMocks();
  });

  // Helper function to wait for async updates
  async function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
  }

  it("renders without errors", () => {
    const element = createElement("c-record-pathway-selection", {
      is: RecordPathwaySelection
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Verify card renders
    const card = element.shadowRoot.querySelector("lightning-card");
    expect(card).not.toBeNull();
    expect(card.title).toBe("Record Succession Pathway Selection");
  });

  it("has recordId property set", () => {
    const element = createElement("c-record-pathway-selection", {
      is: RecordPathwaySelection
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Verify recordId is set (public @api property)
    expect(element.recordId).toBe("500xx000000000AAAA");
  });

  it("displays pathway selection buttons", () => {
    const element = createElement("c-record-pathway-selection", {
      is: RecordPathwaySelection
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Verify instructional text is present
    const componentText = element.shadowRoot.textContent;
    expect(componentText).toContain("Select Succession Pathway");

    // Verify at least one pathway button exists
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    expect(buttons.length).toBeGreaterThan(0);
  });
});
