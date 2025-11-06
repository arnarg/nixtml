{ lib, ... }:
let
  inherit (lib) mkAttr concatStringsSep;

  mkIntOrStringAttr =
    name: value:
    if builtins.isInt value then
      mkAttr name (builtins.toString value)
    else if builtins.isString value then
      mkAttr name value
    else
      builtins.abort "The value provided to attribute \"${name}\" is not of type int or string.";
in
{
  # Simple regular attributes
  abbr = mkAttr "abbr";
  acceptCharset = mkAttr "accept-charset";
  accept = mkAttr "accept";
  action = mkAttr "action";
  alt = mkAttr "alt";
  charset = mkAttr "charset";
  class = mkAttr "class";
  content = mkAttr "content";
  decoding = mkAttr "decoding";
  height = mkIntOrStringAttr "height";
  href = mkAttr "href";
  httpEquiv = mkAttr "http-equiv";
  id = mkAttr "id";
  itemprop = mkAttr "itemprop";
  lang = mkAttr "lang";
  link = mkAttr "link";
  name = mkAttr "name";
  property = mkAttr "property";
  rel = mkAttr "rel";
  src = mkAttr "src";
  target = mkAttr "target";
  title = mkAttr "title";
  type = mkAttr "type";
  width = mkIntOrStringAttr "width";

  # Attribute builders
  aria = key: mkAttr "aria-${key}";
  data = key: mkAttr "data-${key}";
  classes = cs: mkAttr "class" (concatStringsSep " " cs);
}
