open Yorick

(* just for convenience *)

let printf  = Printf.printf
let sprintf = Printf.sprintf
let fprintf = Printf.fprintf

type user =
  { name:       string
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
  { name      = "root"
  ; password  = "xenroot"
  }

(** [fail msg] makes a thread fail *) 
let fail msg = Lwt.fail (Failure msg) 


(** [seq n] return a list of length [n] >=0 with members 1 .. [n]. We
   * use this for the construction of host names. *)
let rec seq n = 
  let rec loop lst = function
  | 0 -> lst
  | n -> loop (n::lst) (n-1)
  in 
    loop [] n


(** [ssh host cmd] executes [cmd] on Vagrant host [host] *)
let ssh host cmd = 
  ?|> "vagrant ssh %s -c \"%s\"" host cmd |> trim

 (** [update host] updates Vagrant host [host] *)
let update name = 
  ?|. "vagrant box update %s" name


(* [hostname cat n] is the name of host [n] in the category [cat] that
 * is used as a prefix for all hosts within one category. [n] is
 * 1-based; hence [n] >= 1. [hostname "host" 2] returns the name for
 * generic host 2.
 *
 * XXX The naming scheme must be compatible with the host definitions in the
 * [Vagrantfile] and in scripts. This heavy coupling is really
 * unfortunate. At the very least, infrastructure should be numbered as
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


(* [configure_storage ()] configures infrastructure machines after spin up
 *)
let configure_storage () =
  let infra = hostname "infrastructure" 1 in
    { iscsi_iqn   = ssh infra "/scripts/get_wwn.py"
    ; storage_ip  = ssh infra "/scripts/get_ip.sh"
    }

(* [get_host host] obains informations about Vagrant host [host]
 *)
let get_host host =
  match ssh host "/scripts/get_public_ip.sh" |> Stringext.split ~on:'.' with 
  | [uuid; ip]  ->  { name = host
                    ; uuid = uuid
                    ; ip   = ip
                    }
  | _           -> failwith (sprintf "failed to get uuid and IP for %s" host) 
