defmodule ReleaseManager.Plugin.Consolidation do
  @name "protocol.consolidation"
  @shortdoc "Performs protocol consolidation for your release."
  
  use    ReleaseManager.Plugin
  alias  ReleaseManager.Config
  alias  ReleaseManager.Utils
  import ReleaseManager.Utils

  def before_release(%Config{verbosity: verbosity}) do
    debug "Performing protocol consolidation..."
    with_env :prod, fn ->
      cond do
        verbosity == :verbose ->
          mix "compile.protocols", :prod, :verbose
        true ->
          mix "compile.protocols", :prod
      end
    end

    # Load relx.config
    relx_config = Utils.rel_file_dest_path("relx.config") |> Utils.read_terms
    # Add overlay to relx.config which copies consolidated dir to release
    consolidated_path = Path.join([File.cwd!, "_build", "prod", "consolidated"])
    overlays = [overlay: [
      {:copy, '#{consolidated_path}', 'lib/consolidated'}
    ]]
    updated = Utils.merge(relx_config, overlays)
    # Persist relx.config
    Utils.write_terms(Utils.rel_file_dest_path("relx.config"), updated)
  end

  def after_release(_), do: nil
  def after_cleanup(_), do: nil
end
