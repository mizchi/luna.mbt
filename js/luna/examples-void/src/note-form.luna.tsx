/** @jsxImportSource @luna_ui/luna/ssr */
import { createSignal } from "@luna_ui/luna";
import { useIslandForm } from "@luna_ui/luna/void/form";

export default function NoteForm(_props: Record<string, never>) {
  const form = useIslandForm({ title: "" });
  const [failure, setFailure] = createSignal("");
  return (
    <form
      method="post"
      action="/?addForm"
      aria-busy={() => form.pending}
      onSubmit={async (event: Event) => {
        event.preventDefault();
        setFailure("");
        try {
          await form.post("/?add");
        } catch (error) {
          setFailure(error instanceof Error ? error.message : "Submission failed");
        }
      }}
    >
      <label>
        Luna title
        <input
          name="title"
          ref={(input) => form.setData("title", (input as HTMLInputElement).value)}
          value={() => form.data.title}
          onInput={(event: Event) =>
            form.setData("title", (event.target as HTMLInputElement).value)
          }
          aria-describedby="luna-form-error"
        />
      </label>
      <p id="luna-form-error" role="alert">
        {() => form.errors.title ?? form.error?.message ?? failure()}
      </p>
      <button disabled={() => form.pending}>Save with Luna</button>
    </form>
  );
}
