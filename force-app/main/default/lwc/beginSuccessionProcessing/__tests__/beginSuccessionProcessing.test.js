import { createElement } from "lwc";
import BeginSuccessionProcessing from "c/beginSuccessionProcessing";
import updateCase from "@salesforce/apex/BeginSuccessionProcessingController.updateVerificationStatus";

// Mock Apex controller
jest.mock(
  "@salesforce/apex/BeginSuccessionProcessingController.updateVerificationStatus",
  () => {
    return {
      default: jest.fn()
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

describe("c-begin-succession-processing", () => {
  afterEach(() => {
    // Reset DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    // Reset mocks
    jest.clearAllMocks();
  });

  /**
   * Helper function to wait for promises to resolve
   */
  async function flushPromises() {
    return new Promise((resolve) => setImmediate(resolve));
  }

  it("renders without errors", () => {
    const element = createElement("c-begin-succession-processing", {
      is: BeginSuccessionProcessing
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Verify card renders
    const card = element.shadowRoot.querySelector("lightning-card");
    expect(card).not.toBeNull();
    expect(card.title).toBe("Begin Succession Processing");
  });

  it("has recordId property set", () => {
    const element = createElement("c-begin-succession-processing", {
      is: BeginSuccessionProcessing
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Verify recordId is set (public @api property)
    expect(element.recordId).toBe("500xx000000000AAAA");
  });

  it("displays workflow steps", () => {
    const element = createElement("c-begin-succession-processing", {
      is: BeginSuccessionProcessing
    });
    document.body.appendChild(element);

    // Verify instructional text is present
    const componentText = element.shadowRoot.textContent;
    expect(componentText).toContain("Mark verification as complete");
    expect(componentText).toContain("Create the first contact attempt task");
    expect(componentText).toContain("Begin the 5-phase succession workflow");
  });

  it("displays begin succession button", () => {
    const element = createElement("c-begin-succession-processing", {
      is: BeginSuccessionProcessing
    });
    document.body.appendChild(element);

    // Verify button exists with correct label
    const button = element.shadowRoot.querySelector("lightning-button");
    expect(button).not.toBeNull();
    expect(button.label).toContain("Begin Succession Processing");
  });

  it("calls Apex method on button click with success", async () => {
    // Mock successful Apex response
    updateCase.mockResolvedValue({
      success: true,
      message: "Succession processing started successfully"
    });

    const element = createElement("c-begin-succession-processing", {
      is: BeginSuccessionProcessing
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Get button and click it
    const button = element.shadowRoot.querySelector("lightning-button");
    button.click();

    // Wait for promises to resolve
    await flushPromises();

    // Verify Apex method was called with correct parameter
    expect(updateCase).toHaveBeenCalledWith({
      caseId: "500xx000000000AAAA"
    });
  });

  it("shows success toast on successful update", async () => {
    // Mock successful Apex response
    updateCase.mockResolvedValue({
      success: true,
      message: "Succession processing started successfully"
    });

    const element = createElement("c-begin-succession-processing", {
      is: BeginSuccessionProcessing
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Spy on dispatchEvent
    const toastHandler = jest.fn();
    element.addEventListener("lightning__showtoast", toastHandler);

    // Click button
    const button = element.shadowRoot.querySelector("lightning-button");
    button.click();

    // Wait for promises
    await flushPromises();

    // Verify success toast was dispatched
    expect(toastHandler).toHaveBeenCalled();
    const toastEvent = toastHandler.mock.calls[0][0];
    expect(toastEvent.detail.title).toBe("Success");
    expect(toastEvent.detail.message).toBe(
      "Succession processing started successfully"
    );
    expect(toastEvent.detail.variant).toBe("success");
  });

  it("closes modal on successful update", async () => {
    // Mock successful Apex response
    updateCase.mockResolvedValue({
      success: true,
      message: "Succession processing started successfully"
    });

    const element = createElement("c-begin-succession-processing", {
      is: BeginSuccessionProcessing
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Spy on close event
    const closeHandler = jest.fn();
    element.addEventListener("close", closeHandler);

    // Click button
    const button = element.shadowRoot.querySelector("lightning-button");
    button.click();

    // Wait for promises
    await flushPromises();

    // Verify close event was dispatched
    expect(closeHandler).toHaveBeenCalled();
  });

  it("shows error toast when Apex returns failure", async () => {
    // Mock Apex response with failure
    updateCase.mockResolvedValue({
      success: false,
      message: "Case has already been verified"
    });

    const element = createElement("c-begin-succession-processing", {
      is: BeginSuccessionProcessing
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Spy on dispatchEvent
    const toastHandler = jest.fn();
    element.addEventListener("lightning__showtoast", toastHandler);

    // Click button
    const button = element.shadowRoot.querySelector("lightning-button");
    button.click();

    // Wait for promises
    await flushPromises();

    // Verify error toast was dispatched
    expect(toastHandler).toHaveBeenCalled();
    const toastEvent = toastHandler.mock.calls[0][0];
    expect(toastEvent.detail.title).toBe("Error");
    expect(toastEvent.detail.message).toBe("Case has already been verified");
    expect(toastEvent.detail.variant).toBe("error");
  });

  it("does not close modal when Apex returns failure", async () => {
    // Mock Apex response with failure
    updateCase.mockResolvedValue({
      success: false,
      message: "Case has already been verified"
    });

    const element = createElement("c-begin-succession-processing", {
      is: BeginSuccessionProcessing
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Spy on close event
    const closeHandler = jest.fn();
    element.addEventListener("close", closeHandler);

    // Click button
    const button = element.shadowRoot.querySelector("lightning-button");
    button.click();

    // Wait for promises
    await flushPromises();

    // Verify close event was NOT dispatched
    expect(closeHandler).not.toHaveBeenCalled();
  });

  it("shows error toast when Apex throws exception", async () => {
    // Mock Apex throwing an error
    updateCase.mockRejectedValue(
      new Error("Network error or insufficient permissions")
    );

    const element = createElement("c-begin-succession-processing", {
      is: BeginSuccessionProcessing
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Spy on dispatchEvent
    const toastHandler = jest.fn();
    element.addEventListener("lightning__showtoast", toastHandler);

    // Spy on console.error to verify error logging
    const consoleErrorSpy = jest
      .spyOn(console, "error")
      .mockImplementation(() => {});

    // Click button
    const button = element.shadowRoot.querySelector("lightning-button");
    button.click();

    // Wait for promises
    await flushPromises();

    // Verify error was logged
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      "Error updating verification status:",
      expect.any(Error)
    );

    // Verify error toast was dispatched
    expect(toastHandler).toHaveBeenCalled();
    const toastEvent = toastHandler.mock.calls[0][0];
    expect(toastEvent.detail.title).toBe("Error");
    expect(toastEvent.detail.message).toBe(
      "An error occurred while starting succession processing"
    );
    expect(toastEvent.detail.variant).toBe("error");

    // Restore console.error
    consoleErrorSpy.mockRestore();
  });

  it("disables button during loading", async () => {
    // Mock Apex with delayed response
    updateCase.mockImplementation(
      () =>
        new Promise((resolve) => {
          setTimeout(() => {
            resolve({
              success: true,
              message: "Success"
            });
          }, 100);
        })
    );

    const element = createElement("c-begin-succession-processing", {
      is: BeginSuccessionProcessing
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    const button = element.shadowRoot.querySelector("lightning-button");

    // Initially not disabled
    expect(button.disabled).toBe(false);

    // Click button
    button.click();

    // Should be disabled immediately
    return Promise.resolve().then(() => {
      expect(button.disabled).toBe(true);
    });
  });

  it("re-enables button after operation completes", async () => {
    // Mock successful response
    updateCase.mockResolvedValue({
      success: true,
      message: "Success"
    });

    const element = createElement("c-begin-succession-processing", {
      is: BeginSuccessionProcessing
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    const button = element.shadowRoot.querySelector("lightning-button");

    // Click button
    button.click();

    // Wait for promises
    await flushPromises();

    // Button should be re-enabled
    expect(button.disabled).toBe(false);
  });

  it("re-enables button after error", async () => {
    // Mock error response
    updateCase.mockRejectedValue(new Error("Test error"));

    const element = createElement("c-begin-succession-processing", {
      is: BeginSuccessionProcessing
    });
    element.recordId = "500xx000000000AAAA";
    document.body.appendChild(element);

    // Suppress console.error for this test
    const consoleErrorSpy = jest
      .spyOn(console, "error")
      .mockImplementation(() => {});

    const button = element.shadowRoot.querySelector("lightning-button");

    // Click button
    button.click();

    // Wait for promises
    await flushPromises();

    // Button should be re-enabled even after error
    expect(button.disabled).toBe(false);

    // Restore console.error
    consoleErrorSpy.mockRestore();
  });
});
