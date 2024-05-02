import { NetworkLogo } from "./NetworkLogo";
import { renderNetworkName } from "../utils";
import { NetworkProps } from "./Transfer";

type NetworkPickerProps = NetworkProps & { onClick: () => void; };

export function NetworkPicker({ network, onClick }: NetworkPickerProps) {
  return (
    <div
      onClick={onClick}
      className="flex flex-row p-1 px-2 text-primary text-xs sm:text-sm font-semibold border-[0px] bg-inverted/5 border-grey-100 dark:border-grey-800 rounded-lg cursor-pointer hover:bg-inverted/15 dark:hover:bg-grey-800 hover:shadow-sm transition-colors duration-125 ease-in-out items-center space-x-2"
    >
      <NetworkLogo network={network} />
      <span className="hidden md:flex">{renderNetworkName(network)}</span>
      <svg
        className=" transition-all "
        xmlns="http://www.w3.org/2000/svg"
        width="10"
        height="10"
        fill="currentColor"
        viewBox="0 0 330 330"
      >
        <path d="M325.607 79.393c-5.857-5.857-15.355-5.858-21.213.001l-139.39 139.393L25.607  79.393c-5.857-5.857-15.355-5.858-21.213.001-5.858 5.858-5.858 15.355 0 21.213l150.004  150a14.999 14.999 0 0 0 21.212-.001l149.996-150c5.859-5.857 5.859-15.355.001-21.213z"></path>
      </svg>
    </div>
  );
}
