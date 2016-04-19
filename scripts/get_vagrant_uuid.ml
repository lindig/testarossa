open Lwt
open Xen_api
open Xen_api_lwt_unix

let uri = ref "http://gandalf.uk.xensource.com"
let username = ref "root"
let password = ref "xenroot"

let lwt_read file = Lwt_io.lines_of_file file |> Lwt_stream.to_list
    
let get_ref name = lwt_read (Printf.sprintf ".vagrant/machines/%s/xenserver/id" name) >|= List.hd

let main name =
  let rpc = make !uri in
  let t =
    Session.login_with_password rpc !username !password "1.0" "testarossa"
    >>= fun session_id ->
    Lwt.catch
      (fun () ->
	get_ref name >>= fun vm_ref ->
	VM.get_uuid rpc session_id vm_ref >>= fun uuid ->
	Printf.printf "%s\n" uuid;
	return ())
      (fun _ -> return ())
    >>= fun () -> Session.logout rpc session_id
  in
  Lwt_main.run t;
  `Ok

open Cmdliner

let name_arg =
  let doc = "Name of the Vagrant VM whose UUID is required" in
  Arg.(value & pos 0 string "" & info [] ~docv:"NAME" ~doc)
    
let main_t = Term.(pure main $ name_arg)

let info =
  let doc = "Get the UUID of a vagrant VM running on XenServer" in
  let man = [ `S "BUGS"; `P "Report bug on the github issue tracker" ] in
  Term.info "get_vagrant_uuid" ~version:"1.0" ~doc ~man
    
let () = match Term.eval (main_t, info) with `Error _ -> exit 1 | _ -> exit 0
