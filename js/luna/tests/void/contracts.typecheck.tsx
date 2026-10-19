/** @jsxImportSource @luna_ui/luna/ssr */
import { useActionForm } from "@luna_ui/luna/sol/form";

function solFormContract() {
  const fields = useActionForm({ title: "", count: 0 });
  fields.setData("title", "updated");
  fields.setData("count", 1);
  // @ts-expect-error Field names follow the default data contract.
  fields.setData("unknown", "value");
  // @ts-expect-error Field value types follow the default data contract.
  fields.setData("count", "invalid");
  return fields;
}
export { solFormContract };

export const allowed = (
  <input
    value={() => "Draft"}
    ref={(input) => {
      input.focus();
    }}
  />
);
export const custom = <luna-example data-review="safe" />;

// @ts-expect-error SSR JSX does not expose raw HTML insertion.
export const rawHtml = <div dangerouslySetInnerHTML={{ __html: "review" }} />;
// @ts-expect-error Internal renderer attributes are not public JSX props.
export const internalHtml = <div __innerHTML={() => "review"} />;
// @ts-expect-error Internal ref names must go through the public ref callback.
export const internalRef = <div __ref={() => {}} />;
// @ts-expect-error Hydration keys belong to the renderer.
export const hydrationKey = <div sol:hk="0" />;
