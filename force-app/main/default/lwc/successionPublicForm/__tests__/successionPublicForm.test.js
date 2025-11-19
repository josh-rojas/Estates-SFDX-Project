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

  it("shows error when caseId URL parameter missing", () => {
    // Mock URL without caseId parameter
    delete window.location;
    window.location = { search: "" };

    const element = createElement("c-succession-public-form", {
      is: SuccessionPublicForm
    });
    document.body.appendChild(element);

    // Verify error message is displayed in DOM (current rich error copy)
    const errorText = element.shadowRoot.textContent;
    expect(errorText).toContain("Missing Case Information");
    expect(errorText).toContain(
      "The link you used is missing required information (Case ID)."
    );
  });

  describe("Accessibility", () => {
    it("renders error with aria-live region", async () => {
      delete window.location;
      window.location = { search: "" };

      const element = createElement("c-succession-public-form", {
        is: SuccessionPublicForm
      });
      document.body.appendChild(element);

      await Promise.resolve();

      const errorDiv = element.shadowRoot.querySelector('[role="alert"]');
      expect(errorDiv).not.toBeNull();
      expect(errorDiv.getAttribute("aria-live")).toBe("assertive");
      expect(errorDiv.getAttribute("aria-atomic")).toBe("true");
    });

    it("error alerts have proper aria attributes", async () => {
      delete window.location;
      window.location = { search: "" };

      const element = createElement("c-succession-public-form", {
        is: SuccessionPublicForm
      });
      document.body.appendChild(element);

      await Promise.resolve();

      const errorDiv = element.shadowRoot.querySelector(
        '.slds-scoped-notification[role="alert"]'
      );
      expect(errorDiv).not.toBeNull();
      expect(errorDiv.getAttribute("aria-live")).toBe("assertive");
      expect(errorDiv.getAttribute("aria-atomic")).toBe("true");
    });
  });
});
