include Ast

(* Renaming some of the "external" types so visitors get named correctly. *)
type nsenv  = Namespace_env.env
type fimode = FileInfo.mode
type pos_t  = Pos.t

class virtual ['e] monoid = object (self)
  method private virtual e: 'e
  method private virtual add: 'e -> 'e -> 'e
  method private sum: 'e list -> 'e = List.fold_left self#add self#e
end

class ['e] monoid_sum = object
  inherit ['e] monoid
  method private e = 0
  method private add = (+)
end

class ['e] monoid_product = object
  inherit ['e] monoid
  method private e = 1
  method private add = ( * )
end

class ['self] map_base = object (self : 'self)
  method private on_Pos_t        : 'env -> pos_t  -> pos_t  = fun _ x -> x
  method private on_Namespace_env: 'env -> nsenv  -> nsenv  = fun _ x -> x
  method private on_FileInfo_mode: 'env -> fimode -> fimode = fun _ x -> x
  method private on_string       : 'env -> string -> string = fun _ x -> x
  method private on_int          : 'env -> int    -> int    = fun _ x -> x
  method private on_bool         : 'env -> bool   -> bool   = fun _ x -> x

  method private on_list
    : 'env 'a 'b . ('env -> 'a -> 'b) -> 'env -> 'a list -> 'b list
    = fun f env -> List.map (f env)
  method private on_option
    : 'env 'a 'b . ('env -> 'a -> 'b) -> 'env -> 'a option -> 'b option
    = fun f env -> Option.map ~f:(f env)
end

class ['self] iter_base = object (self : 'self)
  method private on_Pos_t        : 'env -> pos_t  -> unit = fun _ _ -> ()
  method private on_Namespace_env: 'env -> nsenv  -> unit = fun _ _ -> ()
  method private on_FileInfo_mode: 'env -> fimode -> unit = fun _ _ -> ()
  method private on_string       : 'env -> string -> unit = fun _ _ -> ()
  method private on_int          : 'env -> int    -> unit = fun _ _ -> ()
  method private on_bool         : 'env -> bool   -> unit = fun _ _ -> ()

  method private on_list
    : 'env 'a . ('env -> 'a -> unit) -> 'env -> 'a list -> unit
    = fun f env -> List.iter (f env)
  method private on_option
    : 'env 'a . ('env -> 'a -> unit) -> 'env -> 'a option -> unit
    = fun f env -> Option.iter ~f:(f env)
end

class ['self] endo_base = object (self : 'self)
  method private on_Pos_t        : 'env -> pos_t  -> pos_t  = fun _ x -> x
  method private on_Namespace_env: 'env -> nsenv  -> nsenv  = fun _ x -> x
  method private on_FileInfo_mode: 'env -> fimode -> fimode = fun _ x -> x
  method private on_string       : 'env -> string -> string = fun _ x -> x
  method private on_int          : 'env -> int    -> int    = fun _ x -> x
  method private on_bool         : 'env -> bool   -> bool   = fun _ x -> x

  method private on_list
    : 'env 'a . ('env -> 'a -> 'a) -> 'env -> 'a list -> 'a list
    = fun f env xs ->
    let rec aux env xs counter =
      match xs with
      | [] -> xs
      | [y1] ->
        let z1 = f env y1 in
        if y1 == z1 then xs
        else [z1]
      | [y1; y2] ->
        let z1 = f env y1 in
        let z2 = f env y2 in
        if y1 == z1 && y2 == z2 then xs
        else [z1; z2]
      | [y1; y2; y3] ->
        let z1 = f env y1 in
        let z2 = f env y2 in
        let z3 = f env y3 in
        if y1 == z1 && y2 == z2 && y3 == z3 then xs
        else [z1; z2; z3]
      | [y1; y2; y3; y4] ->
        let z1 = f env y1 in
        let z2 = f env y2 in
        let z3 = f env y3 in
        let z4 = f env y4 in
        if y1 == z1 && y2 == z2 && y3 == z3 && y4 == z4 then xs
        else [z1; z2; z3; z4]
      | [y1; y2; y3; y4; y5] ->
        let z1 = f env y1 in
        let z2 = f env y2 in
        let z3 = f env y3 in
        let z4 = f env y4 in
        let z5 = f env y5 in
        if y1 == z1 && y2 == z2 && y3 == z3 && y4 == z4 && y5 == z5 then xs
        else [z1; z2; z3; z4; z5]
      | y1::y2::y3::y4::y5::ys ->
        let z1 = f env y1 in
        let z2 = f env y2 in
        let z3 = f env y3 in
        let z4 = f env y4 in
        let z5 = f env y5 in
        let zs =
          if counter > 1000 then
            aux_slow env ys [] ys false
          else
            aux env ys (counter + 1)
        in
        if y1 == z1 && y2 == z2 && y3 == z3 && y4 == z4 && y5 == z5 && ys == zs
        then xs
        else z1::z2::z3::z4::z5::zs
    and aux_slow env xs acc original_list has_new_elements =
      match xs with
      | [] -> if has_new_elements then List.rev acc else original_list
      | y1::ys ->
        let z1 = f env y1 in
        aux_slow env ys (z1::acc) original_list (has_new_elements || y1 != z1)
    in
    aux env xs 0

  method private on_option
    : 'env 'a . ('env -> 'a -> 'a) -> 'env -> 'a option -> 'a option
    = fun f env x ->
      match x with
      | None -> x
      | Some y ->
        let z = f env y in
        if y == z then x else Some z
end

class virtual ['self] reduce_base = object (self : 'self)
  inherit ['acc] monoid
  method private on_Pos_t
    : 'env -> pos_t  -> 'acc = fun _ _ -> self#e
  method private on_Namespace_env
    : 'env -> nsenv  -> 'acc = fun _ _ -> self#e
  method private on_FileInfo_mode
    : 'env -> fimode -> 'acc = fun _ _ -> self#e
  method private on_string
    : 'env -> string -> 'acc = fun _ _ -> self#e
  method private on_int
    : 'env -> int    -> 'acc = fun _ _ -> self#e
  method private on_bool
    : 'env -> bool   -> 'acc = fun _ _ -> self#e

  method private on_list
    : 'env 'a . ('env -> 'a -> 'acc) -> 'env -> 'a list -> 'acc
    = fun f env xs ->
      match xs with
      | []    -> self#e
      | y::ys ->
        let z  = f env y in
        let zs = self#on_list f env ys in
        self#add z zs
  method private on_option
    : 'env 'a . ('env -> 'a -> 'acc) -> 'env -> 'a option -> 'acc
    = fun f env -> Option.value_map ~default:self#e ~f:(f env)
end
