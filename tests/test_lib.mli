
type host = 
  { name : string
  ; ip : string
  ; uuid : string; 
  }
type storage_server = 
  { storage_ip : string
  ; iscsi_iqn : string; 
  }

type rpc = Rpc.call -> Rpc.response Lwt.t

type user
val root: user

(* Utilities *)  

val meg : int -> int64
(** [meg n] = n*2^20 *)

val seq : int -> int list
(** [seq n] return a list of length [n] >=0 with members 1 .. [n]. We
    use this for the construction of host names. *)

val fail : string -> 'a Lwt.t
(** [fail msg] makes a thread fail *)

module Vagrant : sig
  val ssh : string -> string -> string
  (** [ssh host cmd] executes [cmd] on Vagrant host [host] *)
  
  val update : string -> unit
  (** [update host] updates Vagrant host [host] *)
  
  val hostname : string -> int -> string
  (** [hostname cat n] is the name of host [n] in the category [cat] that
    * is used as a prefix for all hosts within one category. [n] is
    * 1-based; hence [n] >= 1. [hostname "host" 2] returns the name for
    * generic host 2.
    *
    * xxx the naming scheme must be compatible with the host definitions in the
    * [vagrantfile] and in scripts. this heavy coupling is really
    * unfortunate. at the very least, infrastructure should be numbered as
    * well.
    *) 
 
  val spin_up : int -> int -> unit
  (** [spin_up hosts infra] spins up with vagrant an environment with
    * [hosts] generic hosts and [infra] infrastructure machines
    *)
  
  val configure_storage : unit -> storage_server
  (** [spin_up hosts infra] spins up with vagrant an environment with
    * [hosts] generic hosts and [infra] infrastructure machines
    *)

  val get_host : string -> host
  (** [get_host host] obtains informations about Vagrant host [host]
    *)
end

val with_session :
  rpc -> user -> (rpc -> string -> 'a Lwt.t) -> 'a Lwt.t
