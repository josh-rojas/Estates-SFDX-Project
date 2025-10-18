import { createElement } from "lwc";
import SuccessionPublicForm from "c/successionPublicForm";

describe("c-succession-public-form", () => {
  afterEach(() => {
    // Reset DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }

    // Reset window.location.search
    delete window.location;
    window.location = { search: "" };
  });

  // Helper function to wait for async updates
  async function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
  }

  it("renders without errors", () => {
    // Mock URL parameter
    delete window.location;
    window.location = { search: "?caseId=500xx000000000AAAA" };

    const element = createElement("c-succession-public-form", {
      is: SuccessionPublicForm
    });
    document.body.appendChild(element);

    // Verify component renders
    const container = element.shadowRoot.querySelector(".succession-scope");
    expect(container).not.toBeNull();
  });

  it("displays form title", () => {
    const element = createElement("c-succession-public-form", {
      is: SuccessionPublicForm
    });
    document.body.appendChild(element);

    // Verify form title is displayed
    const componentText = element.shadowRoot.textContent;
    expect(componentText).toContain("Succession Pathway Selection Form");
  });

  it("shows error when caseId URL parameter missing", async () => {
    // Mock URL without caseId parameter
    delete window.location;
    window.location = { search: "" };

    const element = createElement("c-succession-public-form", {
      is: SuccessionPublicForm
    });
    document.body.appendChild(element);

    await flushPromises();

    // Verify error message is displayed in DOM
    const errorText = element.shadowRoot.textContent;
    expect(errorText).toContain("Invalid URL");
    expect(errorText).toContain("Case ID parameter is missing");
  });
});
