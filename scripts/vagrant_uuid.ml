open Xen_api
open Xen_api_lwt_unix

module CMD  = Cmdliner
let return  = Lwt.return
let (>>=)   = Lwt.(>>=)
let (>|=)   = Lwt.(>|=)

let server = "http://gandalf.uk.xensource.com"

type user =
  { username:   string
  ; password:   string
  }

let root = 
  { username = "root"
  ; password = "xenroot"
  }

let lwt_read file = Lwt_io.lines_of_file file |> Lwt_stream.to_list
    
let main host =
  let rpc  = make server in
  let id   = Printf.sprintf ".vagrant/machines/%s/xenserver/id" host in
  let thread =
    Session.login_with_password rpc root.username root.password "1.0" "testarossa"
    >>= fun session ->
    Lwt.catch
      (fun () ->
        lwt_read id >|= List.hd >>= fun vm ->
	VM.get_uuid rpc session vm >>= fun uuid ->
	return (Printf.printf "%s\n" uuid))
      (fun _ -> return ())
    >>= fun () -> Session.logout rpc session
  in
  Lwt_main.run thread;
  `Ok


let name_arg =
  let doc = "Name of the Vagrant VM whose UUID is required" in
  CMD.Arg.(value & pos 0 string "" & info [] ~docv:"NAME" ~doc)
    
let main_t = CMD.Term.(pure main $ name_arg)

let info =
  let doc = "Report UUID of a vagrant VM running on XenServer on stdout" in
  let man = [ `S "BUGS"; `P "Report bug on the github issue tracker" ] in
  CMD.Term.info "get_vagrant_uuid" ~version:"1.0" ~doc ~man
    
let () = 
  match CMD.Term.eval (main_t, info) with 
  | `Error _  -> exit 1 
  | _         -> exit 0
