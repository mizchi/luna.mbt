// ///|
// struct TestStruct {
//   value : String
//   internal_func : () -> String
// }

// ///|
// pub fn TestStruct::fff(self : Self) -> String {
//   self.value
// }

// ///|
// struct TestStructWrapper(TestStruct)

// ///|
// fn TestStruct::outer(self : Self) -> TestStructWrapper {
//   TestStructWrapper(self)
// }

// externa

// pub fn[X] inspect_x(s : X) ->  {
//   inspect((s.0).fff())
// }

// ///|
// test {
//   let inner = TestStruct::{
//     value: "Hello".to_string(),
//     internal_func: fn() { "Internal".to_string() },
//   }
//   let outer = TestStructWrapper(inner)
//   // outer.value
//   (outer.internal_func)() |> inspect

//   // inspect(outer.0.fff())
//   // inspect(outer.0.fff())

//   // let wrapped = s.outer()
//   // let unwrapped = wrapped.0
//   // assert(unwrapped.fff() == "Hello")
// }
