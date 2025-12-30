// Import Luna CSS like Tailwind CSS
import "virtual:luna.css";

console.log("Luna CSS loaded via virtual:luna.css");

// Test dynamic element with CSS classes
const container = document.getElementById("dynamic-test");
if (container) {
  const div = document.createElement("div");
  div.className = "_swuc _3m33u _5qn6e _37twz _1bc6l";
  div.style.padding = "20px";
  div.innerHTML = `
    <span class="_5xtrf _9qup5">Dynamic element with Luna CSS classes</span>
  `;
  container.appendChild(div);
}
