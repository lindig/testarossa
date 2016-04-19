open Yorick
open Xen_api_lwt_unix

(* just for convenience *)

let printf  = Printf.printf
let sprintf = Printf.sprintf
let fprintf = Printf.fprintf

(** the type of the [rpc] parameter in the Xen API *) 
type rpc = Rpc.call -> Rpc.response Lwt.t

type origin =
  { system:     string
  ; version:    string
  }

let origin =
  { system  = "testarossa"
  ; version = "1.0"
  }


type user =
  { username:   string
  ; password:   string
  }

type host = 
  { name:   string
  ; ip:     string
  ; uuid:   string
  }

type storage_server = 
  { storage_ip:   string
  ; iscsi_iqn:    string
  }

(** [meg n] = n*2^20 *)
let meg n = Int64.(mul 1024L @@ mul 1024L @@ of_int n)

(** [root] credentials *)
let root =
  { username  = "root"
  ; password  = "xenroot"
  }

(** [fail msg] makes a thread fail *) 
let fail msg = Lwt.fail (Failure msg) 


(** [seq n] return a list of length [n] >=0 with members 1 .. [n]. We
   * use this for the construction of host names. *)
let seq n = 
  let rec loop lst = function
  | 0 -> lst
  | n -> loop (n::lst) (n-1)
  in 
    loop [] n


module Vagrant = struct
  (* I believe this Vagrant infrastructure is quite brittle. It relies 
   * too much on fixed names and the execution of scripts in 
   * remote shells -- lindig
   *)

  (** [ssh host cmd] executes [cmd] on Vagrant host [host] *)
  let ssh host cmd = 
    ?|> "vagrant ssh %s -c \"%s\"" host cmd |> trim

   (** [update host] updates Vagrant host [host] *)
  let update name = 
    ?|. "vagrant box update %s" name


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
  let hostname (cat: string) (n: int) = match cat, n with
    | "infrastructure", _ -> "infrastructure"
    | cat             , n -> sprintf "%s%d" cat n 

  (** [spin_up hosts infra] spins up with vagrant an environment with
    * [hosts] generic hosts and [infra] infrastructure machines
    *)
  let spin_up hosts infra =
    assert (hosts >= 1);
    assert (infra  = 1); (* for now *)
    let hosts = seq hosts |> List.map (hostname "host")  in
    let infra = seq infra |> List.map (hostname "infrastructure") in
    let arg   = String.concat " " (hosts @ infra) in
      ?|. "vagrant up %s --parallel --provider=xenserver" arg


  (** [configure_storage ()] configures infrastructure machines after spin up
    *)
  let configure_storage () =
    let infra = hostname "infrastructure" 1 in
      { iscsi_iqn   = ssh infra "/scripts/get_wwn.py"
      ; storage_ip  = ssh infra "/scripts/get_ip.sh"
      }

  (** [get_host host] obtains informations about Vagrant host [host]
    *)
  let get_host host =
    match ssh host "/scripts/get_public_ip.sh" |> Stringext.split ~on:'.' with 
    | [uuid; ip]  ->  { name = host
                      ; uuid = uuid
                      ; ip   = ip
                      }
    | _           -> failwith (sprintf "failed to get uuid and IP for %s" host) 

end

(** [with_user rpc user f] executes [f rpc session] in the context of
  * a [session] created for [user]. [session] is guaranteed to be
  * closed afterwards.
  *)
let with_user (rpc:rpc) user f =
    Session.login_with_password 
      rpc user.username user.password origin.version origin.system
    >>= fun session ->
    Lwt.catch 
      (fun () ->
        f rpc session >>= fun result ->
        Session.logout rpc session >>= fun () ->
        return result)
      (fun e -> 
        Session.logout rpc session >>= fun () -> Lwt.fail e)

